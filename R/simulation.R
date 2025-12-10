#' Helper to resolved defined symbols in our formulas
#'
#' This function evaluates an expression in a given environment.
#' @param expr An expression to evaluate
#' @param env An environment to evaluate the expression in
#' @param n The number of values to generate if the expression is a distribution
#' @return The evaluated value as it is, no assumption on its type
#' @keywords internal
resolve_symbol <- function(expr, env, n) {
  # evaluate expression once in the given environment
  val <- eval(expr, envir = env)

  if (base::inherits(val, "distribution")) {
    out <- distributional::generate(val, n)[[1]]
    return(base::as.numeric(out))
  } else {
    return(val)
  }
}


#' Evaluate a list of formulas sequentially with data
#'
#' This function evaluates a list of formulas sequentially, allowing later
#' formulas to reference
#' @param formulas A list of formulas to evaluate
#' @param data A list of named values to use as the initial environment
#' @param n The number of values to generate for each formula
#' @return A named list of evaluated values with length n
#' @keywords internal
evaluate_with_dt <- function(formulas, data = list(), n) {
  # validate and convert data
  if (is.data.frame(data)) {
    data <- as.list(data)
  } else if (!is.list(data)) {
    stop("Data must be a list or data frame.")
  }

  # prepare for evaluation
  lhs_names <- sapply(formulas, function(f) as.character(rlang::f_lhs(f)))
  rhs_exprs <- lapply(formulas, function(f) rlang::f_rhs(f))

  # new data list
  res_list <- vector("list", length(rhs_exprs))
  names(res_list) <- lhs_names
  env <- list2env(data, parent = baseenv())

  # sequential evaluation
  for (i in seq_along(rhs_exprs)) {
    val <- resolve_symbol(rhs_exprs[[i]], env = env, n)

    # input validation and recycling
    if (length(val) == 1) {
      val <- rep(val, n)
    } else if (length(val) != n) {
      stop(
        paste0(
          "The length of the evaluated result for '",
          lhs_names[i],
          "' must be either 1 or n (", n, ")."
        )
      )
    }

    # environment update
    env[[lhs_names[i]]] <- val

    res_list[[i]] <- val
  }

  res_list <- modifyList(data, res_list)

  for (i in seq_along(res_list)) {
    val <- res_list[[i]]
    len <- length(val)
    if (len == n) {
      next
    } else if (n %% len == 0) {
      res_list[[i]] <- rep(val, n / len)
    } else {
      stop(
        paste0(
          "The length of '",
          names(res_list)[i],
          "' must be either 1 or a multiple of n (",
          n,
          ").",
          "But got length ",
          len,
          "."
        )
      )
    }
  }

  return(res_list)
}


#' Run a given condition with multiple trials
#'
#' This function runs multiple trials for a given condition using the specified
#' @param condition_setting A list of named values representing the condition
#' settings
#' @param between_trial_formulas A list of formulas defining the between-trial
#' parameters
#' @param item_formulas A list of formulas defining the item parameters
#' @param n_trials The number of trials to simulate
#' @param n_items The number of items per trial
#' @param max_reached The threshold for evidence accumulation
#' @param max_t The maximum time to simulate
#' @param dt The step size for each increment
#' @param noise_mechanism The noise mechanism to use ("add" or "mult")
#' @param noise_factory A function that takes condition_setting and returns a
#' noise function with signature function(n, dt)
#' @param backend The backend implementation to use ("ddm", "ddm-2b", or "lca-gi")
#' @param trajectories Whether to return full output including trajectories.
#' @return A list containing the simulation results and condition parameters
#' @keywords internal
run_condition <- function(
    condition_setting,
    between_trial_formulas,
    item_formulas,
    n_trials,
    n_items,
    max_reached,
    max_t,
    dt,
    noise_mechanism,
    noise_factory,
    backend,
    trajectories = FALSE) {
  # validate backend parameter
  if (!backend %in% c("ddm", "ddm-2b", "lca-gi")) {
    stop("backend must be either 'ddm', 'ddm-2b', or 'lca-gi'")
  }

  # prepare
  cond_params <- evaluate_with_dt(
    formulas = between_trial_formulas,
    data = condition_setting,
    n = n_trials
  )

  trial_params_list <- vector("list", n_trials)
  for (i in seq_len(n_trials)) {
    trial_params_list[[i]] <- lapply(cond_params, function(x) x[i])
  }

  # run trials based on backend type
  cond_res <- lapply(
    trial_params_list,
    function(trial_setting) {
      switch(backend,
        "ddm" = run_trial_ddm(
          trial_setting = trial_setting,
          item_formulas = item_formulas,
          n_items = n_items,
          max_reached = max_reached,
          max_t = max_t,
          dt = dt,
          noise_mechanism = noise_mechanism,
          noise_factory = noise_factory,
          trajectories = trajectories
        ),
        "ddm-2b" = run_trial_ddm_2b(
          trial_setting = trial_setting,
          item_formulas = item_formulas,
          n_items = n_items,
          max_reached = max_reached,
          max_t = max_t,
          dt = dt,
          noise_mechanism = noise_mechanism,
          noise_factory = noise_factory,
          trajectories = trajectories
        ),
        "lca-gi" = run_trial_lca_gi(
          trial_setting = trial_setting,
          item_formulas = item_formulas,
          n_items = n_items,
          max_reached = max_reached,
          max_t = max_t,
          dt = dt,
          noise_factory = noise_factory,
          trajectories = trajectories
        )
      )
    }
  )

  # Return a list containing both results and condition parameters
  return(list(
    result = cond_res,
    cond_params = cond_params,
    backend = backend
  ))
}


#' Run a chunk of simulation conditions and save results to disk
#'
#' This function processes a chunk of simulation conditions, applies the
#' flatten_simulation_results transformation, and saves the results to disk
#' using Arrow's write_dataset with partitioning by chunk_idx.
#' @param config A eam_simulation_config object containing all simulation
#' parameters
#' @param output_dir The base output directory
#' @param chunk_idx The chunk index for partitioning (1-based)
#' @return Invisible NULL (results are saved to disk)
#' @keywords internal
run_chunk <- function(config, output_dir, chunk_idx) {
  # Reconstruct paths from output_dir using fs_proto
  evaluated_conditions_dir <- file.path(
    output_dir,
    simulation_output_fs_proto$evaluated_conditions_dir
  )
  simulation_dataset_dir <- file.path(
    output_dir,
    simulation_output_fs_proto$dataset_dir
  )

  # Read pre-evaluated condition parameters for this chunk
  chunk_prior_params_df <- arrow::open_dataset(evaluated_conditions_dir) |>
    dplyr::filter(chunk_idx == !!chunk_idx) |>
    dplyr::collect()

  # Sort by condition_idx to ensure proper ordering
  chunk_prior_params_df <- chunk_prior_params_df |>
    dplyr::arrange(condition_idx) # nolint: object_usage_linter

  n_conditions_in_chunk <- nrow(chunk_prior_params_df)

  # Convert rows to list of condition settings (each row becomes a named list)
  condition_params_list <- lapply(
    seq_len(n_conditions_in_chunk),
    function(i) as.list(chunk_prior_params_df[i, , drop = FALSE])
  )

  # run each condition in this chunk
  chunk_results <- lapply(
    seq_len(n_conditions_in_chunk),
    function(i) {
      result <- run_condition(
        condition_setting = condition_params_list[[i]],
        between_trial_formulas = config$between_trial_formulas,
        item_formulas = config$item_formulas,
        n_trials = config$n_trials_per_condition,
        n_items = config$n_items,
        max_reached = config$max_reached,
        max_t = config$max_t,
        dt = config$dt,
        noise_mechanism = config$noise_mechanism,
        noise_factory = config$noise_factory,
        backend = config$backend,
        trajectories = FALSE
      )

      return(result)
    }
  )

  # Transform results to table format
  flat_results <- flatten_simulation_results(chunk_results)

  # Add chunk_idx column for partitioning
  flat_results$chunk_idx <- chunk_idx

  # Save to output directory with partitioning by chunk_idx
  arrow::write_dataset(
    flat_results,
    path = simulation_dataset_dir,
    partitioning = c("chunk_idx"),
    format = "parquet"
  )

  # No need to return anything for out-of-core processing
  return(invisible(NULL))
}

#' Run a full simulation across multiple conditions (serial version)
#'
#' This function runs a complete simulation across multiple conditions serially,
#' with each condition having multiple trials and items. It uses the
#' hierarchical structure: prior -> condition -> trial -> item. All parameters
#' are taken from the configuration object.
#' @param config simulation config object
#' @param output_dir The base output directory
#' @return No return value (results saved to disk)
#' @keywords internal
run_simulation_serial <- function(config, output_dir) {
  # Validate config
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be a eam_simulation_config object")
  }

  # Calculate number of chunks needed
  n_chunks <- ceiling(config$n_conditions / config$n_conditions_per_chunk)

  # Process chunks serially using the standalone run_chunk function
  for (chunk_idx in seq_len(n_chunks)) {
    run_chunk(
      config = config,
      output_dir = output_dir,
      chunk_idx = chunk_idx
    )
  }

  invisible(NULL)
}


#' Run a full simulation across multiple conditions in parallel
#'
#' This function runs a complete simulation across multiple conditions using
#' parallel processing. It splits the conditions into chunks and processes
#' each chunk on separate cores. Each condition has multiple trials and items.
#' It uses the hierarchical structure: prior -> condition -> trial -> item.
#' All parameters are taken from the configuration object.
#' @param config A eam_simulation_config object
#' @param output_dir The base output directory
#' @return No return value (results saved to disk)
#' @keywords internal
run_simulation_parallel <- function(config, output_dir) {
  # Validate config
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be a eam_simulation_config object")
  }

  # Calculate number of chunks needed
  n_chunks <- ceiling(config$n_conditions / config$n_conditions_per_chunk)

  # Create chunk data for parallel processing
  chunked_data <- lapply(seq_len(n_chunks), function(chunk_idx) {
    list(chunk_idx = chunk_idx)
  })

  # setup parallel cluster
  cl <- parallel::makeCluster(min(config$n_cores, length(chunked_data)))
  on.exit(parallel::stopCluster(cl))

  # export necessary objects to cluster
  parallel::clusterExport(
    cl, c(
      # functions
      "run_condition", "run_trial_ddm", "run_trial_ddm_2b", "run_trial_lca_gi",
      "evaluate_with_dt", "resolve_symbol", "accumulate_evidence_ddm",
      "accumulate_evidence_ddm_2b", "accumulate_evidence_lca_gi",
      "flatten_simulation_results", "run_chunk"
    ),
    envir = environment()
  )

  # set RNG seed for parallel workers
  parallel::clusterSetRNGStream(cl, iseed = config$rand_seed)

  # run parallel processing with progress bar
  if (requireNamespace("pbapply", quietly = TRUE)) {
    pbapply::pblapply(
      chunked_data,
      function(chunk_data) {
        run_chunk(
          config = config,
          output_dir = output_dir,
          chunk_idx = chunk_data$chunk_idx
        )
      },
      cl = cl
    )
  } else {
    message("Install 'pbapply' package for progress bar support")
    parallel::parLapply(
      cl,
      chunked_data,
      function(chunk_data) {
        run_chunk(
          config = config,
          output_dir = output_dir,
          chunk_idx = chunk_data$chunk_idx
        )
      }
    )
  }

  invisible(NULL)
}


#' Run a simulation with specified configuration
#'
#' This function runs a complete simulation based on the provided
#' eam_simulation_config object, which is generated by the
#' \code{\link{new_simulation_config}} function.
#' @param config A eam_simulation_config object containing all simulation
#' parameters, you should use \code{\link{new_simulation_config}} to create one.
#' @param output_dir The directory to save out-of-core results (optional,
#' will use temp directory if not provided)
#' @return A S3 object of class eam_simulation_output containing the output
#' information
#' @details
#' This function uses an out-of-core approach to handle potentially large
#' simulation results. Instead of returning a data frame directly, it persists
#' the data to disk and returns an \code{eam_simulation_output} object that
#' contains metadata and file system paths.
#'
#' To access the simulation data, use the following methods on the returned
#' object:
#' \itemize{
#'   \item \code{open_dataset()} - Returns an Arrow Dataset containing the
#'   simulation results, e.g. \code{sim_output$open_dataset()}
#'   \item \code{open_evaluated_conditions()} - Returns an Arrow Dataset
#'   containing the evaluated condition parameters, e.g.
#'   \code{sim_output$open_evaluated_conditions()}
#' }
#'
#' Both methods return Arrow Dataset objects rather than data frames, allowing
#' for efficient querying and filtering before loading data into memory. To
#' convert to a data frame, use \code{dplyr::collect()} or
#' \code{as.data.frame()}.
#'
#' Throughout this package, the \code{eam_simulation_output} object is used as
#' the standard parameter for downstream analysis functions, rather than
#' passing Arrow objects or data frames directly.
#'
#' For multi-item backends, at each discrete time point, only one item can
#' reach the threshold.
#' The precision of this detection depends on the \code{dt}
#' parameter. This design choice was made for performance considerations. For
#' almost all experimental scenarios, it is negligible.
#' But users should be aware of this limitation, if it is critical, try to
#' increase the temporal resolution by reducing \code{dt}.
#' For implementation details,
#' refer to the backend source code (\code{accumulate_evidence_*} functions).
#' @examples
#' # Define formulas for the simulation
#' prior_formulas <- list(
#'   V ~ distributional::dist_uniform(0.1, 1.0),
#'   ndt ~ 0.3,
#'   noise_coef ~ 1
#' )
#'
#' between_trial_formulas <- list()
#'
#' item_formulas <- list(
#'   A_upper ~ 1,
#'   A_lower ~ -1,
#'   V ~ V
#' )
#'
#' # Define noise factory
#' noise_factory <- function(context) {
#'   noise_coef <- context$noise_coef
#'   function(n, dt) {
#'     noise_coef * rnorm(n, mean = 0, sd = sqrt(dt))
#'   }
#' }
#'
#' # Create configuration
#' config <- new_simulation_config(
#'   prior_formulas = prior_formulas,
#'   between_trial_formulas = between_trial_formulas,
#'   item_formulas = item_formulas,
#'   n_conditions = 10,
#'   n_trials_per_condition = 10,
#'   n_items = 5,
#'   max_reached = 5,
#'   max_t = 10,
#'   dt = 0.01,
#'   noise_mechanism = "add",
#'   noise_factory = noise_factory,
#'   model = "ddm",
#'   parallel = FALSE
#' )
#'
#' # Run simulation
#' sim_output <- run_simulation(config)
#'
#' # Access results
#' dataset <- sim_output$open_dataset()
#' dataset # an arrow dataset object
#'
#' # if you want to load it into memory, you can use:
#' df <- as.data.frame(dataset)
#' head(df)
#'
#' # Access evaluated condition parameters
#' cond_dataset <- sim_output$open_evaluated_conditions()
#' df_cond <- as.data.frame(cond_dataset)
#' head(df_cond)
#' @export
run_simulation <- function(config, output_dir = NULL) {
  # Validate config
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be a eam_simulation_config object")
  }

  if (is.null(output_dir)) {
    rand_hex <- paste0(
      sample(c(0:9, letters[1:6]), 8, replace = TRUE),
      collapse = ""
    )
    output_dir <- tempfile(
      pattern = paste0("eam_simulation_output_", rand_hex)
    )
  }

  # Initialize output directory structure
  init_simulation_output_dir(output_dir)

  # Evaluate ALL condition parameters upfront
  prior_params <- evaluate_with_dt(
    formulas = config$prior_formulas,
    data = config$prior_params,
    n = config$n_conditions
  )

  # Prepare data frame with chunk_idx for partitioning
  # Handle case where prior_formulas is empty
  if (length(prior_params) == 0) {
    prior_params_df <- data.frame(
      condition_idx = seq_len(config$n_conditions)
    )
  } else {
    prior_params_df <- as.data.frame(prior_params)
    prior_params_df$condition_idx <- seq_len(config$n_conditions)
  }

  prior_params_df$chunk_idx <- ceiling(
    prior_params_df$condition_idx / config$n_conditions_per_chunk
  )

  # Save evaluated condition parameters with partitioning by chunk_idx
  arrow::write_dataset(
    prior_params_df,
    path = file.path(
      output_dir,
      simulation_output_fs_proto$evaluated_conditions_dir
    ),
    partitioning = c("chunk_idx"),
    format = "parquet"
  )

  if (config$parallel) {
    run_simulation_parallel(
      config = config,
      output_dir = output_dir
    )
  } else {
    run_simulation_serial(
      config = config,
      output_dir = output_dir
    )
  }

  ret <- new_simulation_output(
    simulation_config = config,
    output_dir = output_dir
  )

  # persist the config
  saveRDS(
    config,
    file = file.path(output_dir, simulation_output_fs_proto$config_file)
  )

  ret
}
