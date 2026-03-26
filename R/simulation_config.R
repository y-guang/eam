#' Create a new simulation configuration
#'
#' This function creates a new eam simulation configuration object that
#' contains all parameters needed to run a simulation.
#'
#' @details
#' This function only creates the configuration object and does not run the
#' simulation. To actually execute the simulation, you must pass the returned
#' configuration object to \code{\link{run_simulation}}.
#'
#' \strong{Supported Models:}
#'
#' This package supports three evidence accumulation models. The appropriate
#' backend is automatically selected based on the \code{model} parameter and
#' the parameters defined in your formulas.
#'
#' \describe{
#'   \item{\strong{DDM (Drift Diffusion Model)}}{
#'     Models evidence accumulation towards a single upper threshold. Items
#'     either reach the threshold and are recalled, or time out.
#'
#'     \emph{Required parameters} (must appear in \code{prior_formulas},
#'     \code{between_trial_formulas}, or \code{item_formulas}):
#'     \itemize{
#'       \item \code{A} - Upper decision boundary/threshold
#'       \item \code{V} - Drift rate (evidence accumulation rate)
#'       \item \code{Z} - Starting point of evidence
#'       \item \code{ndt} - Non-decision time
#'     }
#'
#'     Set \code{model = "ddm"}
#'   }
#'   \item{\strong{RDM (Racing Diffusion Model)}}{
#'     Models multiple racing evidence accumulators, each with upper and lower
#'     thresholds for binary decisions (correct/incorrect).
#'
#'     \emph{Required parameters}:
#'     \itemize{
#'       \item \code{A_upper} - Upper decision boundary (correct response)
#'       \item \code{A_lower} - Lower decision boundary (incorrect response)
#'       \item \code{V} - Drift rate
#'       \item \code{Z} - Starting point of evidence
#'       \item \code{ndt} - Non-decision time
#'     }
#'
#'     Set \code{model = "rdm"}. Note: If you set \code{model = "ddm"} but
#'     define \code{A_upper} instead of \code{A}, the model will automatically
#'     switch to RDM.
#'   }
#'   \item{\strong{LCA (Leaky Competing Accumulator)}}{
#'     Models competitive evidence accumulation with leakage and mutual
#'     inhibition between accumulators.
#'
#'     \emph{Required parameters}:
#'     \itemize{
#'       \item \code{A} - Decision threshold
#'       \item \code{V} - Input strength/drift rate
#'       \item \code{Z} - Starting point of evidence
#'       \item \code{ndt} - Non-decision time
#'       \item \code{beta} - Self-excitation/leak parameter
#'       \item \code{k} - Lateral inhibition strength
#'     }
#'
#'     Set \code{model = "lca"}
#'   }
#'   \item{\strong{LFM (Lévy Flight Model)}}{
#'     Uses the same parameters as \code{DDM}. See \code{DDM} above.
#'
#'     Set \code{model = "lfm"}
#'   }
#'   \item{\strong{LBA (Linear Ballistic Accumulator)}}{
#'     Uses the same parameters as \code{RDM}. See \code{RDM} above.
#'
#'     Set \code{model = "lba"}
#'   }
#' }
#'
#' \strong{Note:} All required parameters must be defined at least once across
#' \code{prior_params}, \code{prior_formulas}, \code{between_trial_formulas}, and
#' \code{item_formulas}.
#'
#' \strong{Parameter Hierarchy and Formula Evaluation:}
#'
#' The simulation uses a hierarchical parameter system with sequential formula
#' evaluation, allowing later formulas to reference earlier ones:
#'
#' \enumerate{
#'   \item \strong{prior_params} - Initial constant values available to all formulas
#'   \item \strong{prior_formulas} - Evaluated once per condition, can reference
#'         \code{prior_params}. Use for condition-level parameters that vary
#'         across conditions.
#'   \item \strong{between_trial_formulas} - Evaluated once per trial within each
#'         condition. Can reference both \code{prior_params} and variables from
#'         \code{prior_formulas}. Use for trial-level variability.
#'   \item \strong{item_formulas} - Evaluated once per item within each trial.
#'         Can reference all previous parameters. Use for item-specific parameters.
#' }
#'
#' \strong{Using Distributions:}
#'
#' You can use the \code{distributional} package to define random parameters.
#' For example:
#' \itemize{
#'   \item \code{A ~ distributional::dist_uniform(0.5, 2.0)} - Uniform distribution
#'   \item \code{V_condition ~ distributional::dist_normal(1.0, 0.2)} - Normal distribution
#'   \item \code{sigma ~ 0.5} - Constant value
#'   \item \code{V ~ distributional::dist_normal(V_condition, sigma)} - Reference earlier parameters
#' }
#'
#' Each formula is evaluated sequentially, so you can build complex parameter
#' dependencies. For instance, you might define a base drift rate \code{V} in
#' \code{prior_formulas}, then add trial-level noise in
#' \code{between_trial_formulas}, and finally scale by item position in
#' \code{item_formulas}.
#'
#' @param prior_params A list or data frame of initial values for prior
#' @param prior_formulas A list of formulas defining prior distributions for
#'   condition-level parameters
#' @param between_trial_formulas A list of formulas defining between-trial
#'   parameters
#' @param item_formulas A list of formulas defining item-level parameters
#' @param n_conditions_per_chunk Number of conditions to process per chunk (optional, typically does not need to be set. It determine the storage and in-memory size of each chunk, if you find memory issues, try reducing this number)
#' @param n_conditions Total number of conditions to simulate
#' @param n_trials_per_condition Number of trials per condition
#' @param n_items Number of items per trial
#' @param max_reached Maximum number of items that can be recalled (default: n_items)
#' @param max_t Maximum simulation time
#' @param dt Time step size (default: 0.001)
#' @param noise_mechanism Noise mechanism ("add", "mult_evidence", or "mult_t", default: "add")
#' @param noise_factory Function that creates noise functions.
#' @param model Model name or backend names (e.g., "ddm", "rdm", "lca")
#' @param parallel Whether to run in parallel (default: FALSE)
#' @param n_cores Number of cores for parallel processing (default: NULL, auto-detect)
#' @param rand_seed Random seed for parallel processing (default: NULL)
#' @return An S3 object of class \code{eam_simulation_config} containing validated
#'   simulation parameters. This object should be passed to
#'   \code{\link{run_simulation}} to execute the simulation.
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
#' # print the config
#' config
#'
#' # Run simulation
#' sim_output <- run_simulation(config)
#' sim_output
#' @export
new_simulation_config <- function(
    prior_params = list(),
    prior_formulas = list(),
    between_trial_formulas = list(),
    item_formulas = list(),
    n_conditions_per_chunk = NULL,
    n_conditions,
    n_trials_per_condition,
    n_items,
    max_reached = n_items,
    max_t,
    dt = 0.001,
    noise_mechanism = "add",
    noise_factory = NULL,
    model = "ddm",
    parallel = FALSE,
    n_cores = NULL,
    rand_seed = NULL) {
  # default noise factory
  if (is.null(noise_factory)) {
    noise_factory <- function(condition_setting) {
      function(n, dt) rep(0, n)
    }
  }

  # default number of cores
  if (parallel && is.null(n_cores)) {
    n_cores <- parallel::detectCores() - 1
    if (n_cores < 1) {
      n_cores <- 1
    }
  }

  # default chunk size
  if (is.null(n_conditions_per_chunk)) {
    n_conditions_per_chunk <-
      new_simulation_config.chunk_size.heuristic(
        n_conditions = n_conditions,
        n_trials_per_condition = n_trials_per_condition,
        n_items = n_items,
        parallel = parallel,
        n_cores = n_cores
      )
  }

  # default random seed for parallel processing
  if (parallel && is.null(rand_seed)) {
    rand_seed <- sample.int(.Machine$integer.max, 1)
  }

  # Create configuration list
  config <- list(
    prior_params = prior_params,
    prior_formulas = prior_formulas,
    between_trial_formulas = between_trial_formulas,
    item_formulas = item_formulas,
    n_conditions_per_chunk = n_conditions_per_chunk,
    n_conditions = n_conditions,
    n_trials_per_condition = n_trials_per_condition,
    n_items = n_items,
    max_reached = max_reached,
    max_t = max_t,
    dt = dt,
    noise_mechanism = noise_mechanism,
    noise_factory = noise_factory,
    model = model,
    parallel = parallel,
    n_cores = n_cores,
    rand_seed = rand_seed
  )

  # Route model to backend
  config <- route_model_to_backend(config)

  # Validate the configuration
  validate_simulation_config(config)

  # Create S3 object
  structure(config, class = "eam_simulation_config")
}

validate_simulation_config <- function(config) {
  # Validate required fields exist (following function signature order)
  required_fields <- c(
    "prior_params",
    "prior_formulas",
    "between_trial_formulas",
    "item_formulas",
    "n_conditions_per_chunk",
    "n_conditions",
    "n_trials_per_condition",
    "n_items",
    "max_reached",
    "max_t",
    "dt",
    "noise_mechanism",
    "noise_factory",
    "model",
    "backend",
    "parallel",
    "n_cores",
    "rand_seed"
  )

  missing_fields <- setdiff(required_fields, names(config))
  if (length(missing_fields) > 0) {
    stop(
      "Missing required configuration fields: ",
      paste(missing_fields, collapse = ", ")
    )
  }

  # Validate prior_params is list or data frame
  if (!is.list(config$prior_params) && !is.data.frame(config$prior_params)) {
    stop("prior_params must be a list or data frame")
  }

  # Validate formulas are lists
  formula_params <- c(
    "prior_formulas",
    "between_trial_formulas",
    "item_formulas"
  )
  for (param_name in formula_params) {
    if (!is.list(config[[param_name]])) {
      stop(param_name, " must be a list")
    }
  }

  # Validate numeric parameters (following signature order)
  numeric_params <- c(
    "n_conditions_per_chunk",
    "n_conditions",
    "n_trials_per_condition",
    "n_items",
    "max_reached",
    "max_t",
    "dt"
  )

  for (param_name in numeric_params) {
    param_value <- config[[param_name]]
    if (!is.numeric(param_value) ||
      length(param_value) != 1 ||
      is.na(param_value)
    ) {
      stop(param_name, " must be a single numeric value")
    }
  }

  # Validate positive integers (following signature order)
  positive_int_params <- c(
    "n_conditions_per_chunk",
    "n_conditions",
    "n_trials_per_condition",
    "n_items"
  )
  for (param_name in positive_int_params) {
    param_value <- config[[param_name]]
    if (param_value <= 0 || param_value != floor(param_value)) {
      stop(param_name, " must be a positive integer")
    }
  }

  # Validate max_reached
  if (config$max_reached <= 0 ||
    config$max_reached != floor(config$max_reached)
  ) {
    stop("max_reached must be a positive integer")
  }
  if (config$max_reached > config$n_items) {
    stop("max_reached cannot be greater than n_items")
  }

  # Validate positive numeric values
  positive_params <- c("max_t", "dt")
  for (param_name in positive_params) {
    param_value <- config[[param_name]]
    if (param_value <= 0) {
      stop(param_name, " must be positive")
    }
  }

  # Validate noise mechanism
  valid_noise_mechanisms <- c("add", "mult", "mult_evidence", "mult_t")
  if (!config$noise_mechanism %in% valid_noise_mechanisms) {
    stop(
      "noise_mechanism must be one of: ",
      paste(valid_noise_mechanisms, collapse = ", "),
      ". Got: ", config$noise_mechanism
    )
  }

  # Validate noise_factory is a function
  if (!is.function(config$noise_factory)) {
    stop("noise_factory must be a function")
  }

  # Validate boolean parameters
  if (!is.logical(config$parallel) ||
    length(config$parallel) != 1 ||
    is.na(config$parallel)
  ) {
    stop("parallel must be a single logical value (TRUE or FALSE)")
  }

  # Validate parallel-specific parameters
  if (config$parallel) {
    if (!is.null(config$n_cores)) {
      if (!is.numeric(config$n_cores) ||
        length(config$n_cores) != 1 ||
        is.na(config$n_cores) ||
        config$n_cores <= 0 ||
        config$n_cores != floor(config$n_cores)
      ) {
        stop("n_cores must be a positive integer when specified")
      }
    }

    if (!is.null(config$rand_seed)) {
      if (
        !is.numeric(config$rand_seed) ||
          length(config$rand_seed) != 1 ||
          is.na(config$rand_seed) ||
          config$rand_seed != floor(config$rand_seed)
      ) {
        stop("rand_seed must be an integer when specified")
      }
    }
  }

  invisible(config)
}

#' Print method for eam simulation configuration
#'
#' @param x A eam_simulation_config object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns the input object
#' @export
print.eam_simulation_config <- function(x, ...) {
  cat("eam Simulation Configuration\n")
  cat("=================================\n")
  cat("Model:", x$model, "\n")
  cat("Backend:", x$backend, "\n")
  cat("Conditions:", x$n_conditions, "\n")
  cat("Trials per condition:", x$n_trials_per_condition, "\n")
  cat("Items per trial:", x$n_items, "\n")
  cat("Max reached:", x$max_reached, "\n")
  cat("Max time:", x$max_t, "\n")
  cat("Time step:", x$dt, "\n")
  cat("Noise mechanism:", x$noise_mechanism, "\n")
  if (!is.null(x$n_conditions_per_chunk)) {
    cat("Conditions per chunk:", x$n_conditions_per_chunk, "\n")
  }
  if (!is.null(x$parallel)) {
    cat("Parallel:", x$parallel, "\n")
  }
  if (!is.null(x$n_cores)) {
    cat("Number of cores:", x$n_cores, "\n")
  }

  # Show formula counts
  cat("\nFormulas:\n")
  cat("  Prior formulas:", length(x$prior_formulas), "\n")
  cat("  Between-trial formulas:", length(x$between_trial_formulas), "\n")
  cat("  Item formulas:", length(x$item_formulas), "\n")

  invisible(x)
}

#' Heuristic to calculate optimal chunk size for simulation configuration
#'
#' @param n_conditions Total number of conditions to simulate
#' @param n_trials_per_condition Number of trials per condition
#' @param n_items Number of items per trial
#' @param parallel Whether to run in parallel
#' @param n_cores Number of cores for parallel processing
#' @return Optimal number of conditions per chunk
#' @keywords internal
new_simulation_config.chunk_size.heuristic <- function(
    n_conditions,
    n_trials_per_condition,
    n_items,
    parallel,
    n_cores) {
  # Initial chunk size calculation
  if (parallel) {
    n_partitions <- ceiling(sqrt(n_conditions))
    n_partitions <- max(n_cores, min(n_partitions, n_cores * 10))
    n_conditions_per_chunk <- ceiling(n_conditions / n_partitions)
  } else {
    n_conditions_per_chunk <- n_conditions
  }

  # Apply data size constraint: n_items * n_trials_per_condition * n_conditions_per_chunk < 200,000
  max_chunk_data_size <- 200000
  data_per_condition <- n_items * n_trials_per_condition
  max_conditions_per_chunk <- floor(max_chunk_data_size / data_per_condition)

  if (max_conditions_per_chunk > 0 && n_conditions_per_chunk > max_conditions_per_chunk) {
    n_conditions_per_chunk <- max_conditions_per_chunk
  }

  # Ensure at least 1 condition per chunk
  n_conditions_per_chunk <- max(1, n_conditions_per_chunk)

  return(n_conditions_per_chunk)
}


#' Update a simulation config with posterior parameter values
#'
#' Applies one posterior draw to an existing simulation configuration.
#' For each name in \code{posterior_params}: any matching entry in
#' \code{prior_params} is removed, any matching formula in \code{prior_formulas}
#' is dropped, and the posterior value is appended to \code{prior_params} as a
#' fixed constant.
#'
#' @param config An \code{eam_simulation_config} object.
#' @param posterior_params A named list or data frame of posterior parameter
#'   values representing exactly one posterior draw.
#' @param n_conditions_per_chunk Number of conditions per processing chunk.
#'   \code{NULL} (default) recomputes the value via the internal heuristic.
#' @param n_conditions Total number of conditions to simulate. Defaults to the
#'   value already stored in \code{config}.
#' @param n_trials_per_condition Number of trials per condition. Defaults to
#'   the value already stored in \code{config}.
#' @param n_items Number of items per trial. Defaults to the value already
#'   stored in \code{config}.
#' @return A modified \code{eam_simulation_config} with updated
#'   \code{prior_params}, pruned \code{prior_formulas}, and the four
#'   simulation-dimension fields.
#' @note
#' This helper is intentionally conservative and mainly for teaching,
#' demonstrations, and quick posterior predictive checks. It freezes selected
#' top-level parameters to fixed posterior values for convenience, but it does
#' not reconstruct or reinterpret the full dependency structure of the
#' simulation specification.
#' If \code{config$prior_params} is a data frame with multiple rows, the
#' single posterior draw is broadcast across those rows when inserted.
#'
#' It does not re-route backend selection and does not create a new model.
#' Parameters that appear on the left-hand side of
#' \code{between_trial_formulas} or \code{item_formulas} cannot be replaced
#' automatically. If you need full control and clarity over internal parameter
#' structure, rebuild the configuration manually using
#' \code{\link{new_simulation_config}}.
#' @examples
#' # Load example simulation output and extract its config
#' base_dir <- system.file("extdata", "rdm_minimal", package = "eam")
#' sim_output <- load_simulation_output(file.path(base_dir, "simulation"))
#' sim_config <- sim_output$simulation_config
#'
#' # Create a simple one-draw posterior parameter data frame
#' posterior_params <- data.frame(
#'   V_beta_1 = -0.15
#' )
#'
#' # Update the config by replacing the matching prior entry/formula
#' updated_config <- update_config_from_posterior(
#'   config = sim_config,
#'   posterior_params = posterior_params,
#'   n_conditions = 1,
#'   n_trials_per_condition = 500
#' )
#'
#' # Inspect the updated fixed prior values
#' updated_config$prior_params
#' @export
update_config_from_posterior <- function(
    config,
    posterior_params,
    n_conditions_per_chunk = NULL,
    n_conditions = config$n_conditions,
    n_trials_per_condition = config$n_trials_per_condition,
    n_items = config$n_items) {
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be an eam_simulation_config object")
  }

  if (!is.data.frame(posterior_params) &&
    !(is.list(posterior_params) && !is.null(names(posterior_params)))) {
    stop("posterior_params must be a named list or a named data frame")
  }

  if (is.data.frame(posterior_params) && nrow(posterior_params) != 1L) {
    stop("posterior_params data frame must contain exactly one row (one posterior draw)")
  }

  if (is.list(posterior_params) && !is.data.frame(posterior_params)) {
    value_lengths <- vapply(posterior_params, length, integer(1L))
    if (any(value_lengths != 1L)) {
      bad <- names(posterior_params)[value_lengths != 1L]
      stop(
        "posterior_params list entries must each be a single value. Invalid entries: ",
        paste(bad, collapse = ", ")
      )
    }
  }

  pp_names <- names(posterior_params)
  if (is.null(pp_names) || any(!nzchar(trimws(pp_names)))) {
    stop("posterior_params names must be non-empty")
  }
  if (anyDuplicated(pp_names)) {
    stop("posterior_params names must be unique")
  }

  # Only between_trial and item formula LHS symbols are forbidden — replacing
  # them would silently break downstream formula dependencies.
  other_formulas <- c(config$between_trial_formulas, config$item_formulas)
  other_lhs <- vapply(
    other_formulas,
    function(f) as.character(rlang::f_lhs(f)),
    character(1L)
  )

  conflicts <- intersect(pp_names, other_lhs)
  if (length(conflicts) > 0) {
    msgs <- vapply(conflicts, function(param) {
      for (f in other_formulas) {
        if (as.character(rlang::f_lhs(f)) == param) {
          return(sprintf(
            "posterior_param '%s' is defined in between_trial_formulas or item_formulas via '%s' and cannot be replaced automatically",
            param, deparse(f)
          ))
        }
      }
    }, character(1L))
    stop(
      paste(msgs, collapse = "; "),
      "; due to ambiguity, please build it manually."
    )
  }

  # Validate: every name in posterior_params must exist in prior_params or
  # prior_formulas LHS — no silent creation of new parameters.
  prior_formulas <- config$prior_formulas
  prior_lhs <- vapply(
    prior_formulas,
    function(f) as.character(rlang::f_lhs(f)),
    character(1L)
  )
  valid_targets <- union(names(config$prior_params), prior_lhs)
  unknown <- setdiff(pp_names, valid_targets)
  if (length(unknown) > 0) {
    stop(
      "The following names in posterior_params are not found in prior_params ",
      "or prior_formulas: ",
      paste(unknown, collapse = ", "),
      ". Please build the config manually if you intend to introduce new parameters."
    )
  }

  # Drop prior_formulas whose LHS is being replaced by a posterior value.
  prior_formulas <- prior_formulas[!(prior_lhs %in% pp_names)]

  # Merge into prior_params: remove any existing entries for pp_names first,
  # then append the posterior values (handles both list and data-frame priors).
  prior <- config$prior_params

  if (is.data.frame(prior)) {
    # Drop columns that will be replaced, then append posterior columns.
    prior <- prior[, setdiff(names(prior), pp_names), drop = FALSE]
    post_df <- if (is.data.frame(posterior_params)) {
      posterior_params
    } else {
      as.data.frame(as.list(posterior_params))
    }

    n_prior <- nrow(prior)
    n_post <- nrow(post_df)

    if (n_post == 1L && n_prior > 1L) {
      post_df <- post_df[rep(1L, n_prior), , drop = FALSE]
      rownames(post_df) <- NULL
    } else if (n_post != n_prior) {
      stop(
        "Row count mismatch: prior_params has ", n_prior, " rows but ",
        "posterior_params has ", n_post, " rows. ",
        "Supply exactly one posterior draw (single row), which will be ",
        "broadcast across prior_params rows when needed."
      )
    }

    prior <- cbind(prior, post_df)
  } else {
    # prior is a named list
    prior[intersect(pp_names, names(prior))] <- NULL

    post_list <- if (is.data.frame(posterior_params)) {
      as.list(posterior_params[1L, , drop = FALSE])
    } else {
      posterior_params
    }

    for (nm in pp_names) {
      prior[[nm]] <- post_list[[nm]]
    }
  }

  new_config <- config
  new_config$prior_params <- prior
  new_config$prior_formulas <- prior_formulas
  new_config$n_conditions <- n_conditions
  new_config$n_trials_per_condition <- n_trials_per_condition
  new_config$n_items <- n_items
  new_config$n_conditions_per_chunk <- if (!is.null(n_conditions_per_chunk)) {
    n_conditions_per_chunk
  } else {
    new_simulation_config.chunk_size.heuristic(
      n_conditions = n_conditions,
      n_trials_per_condition = n_trials_per_condition,
      n_items = n_items,
      parallel = new_config$parallel,
      n_cores = new_config$n_cores
    )
  }

  new_config
}
