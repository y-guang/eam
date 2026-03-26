#' ABC posterior predictive check
#'
#' High-level convenience wrapper for posterior predictive checks from
#' \code{abc_abc()} outputs.
#'
#' This function is for teaching and quick demonstrations.
#' It is intentionally specific to one input shape (an \code{abc} object).
#' For step checks, follow these functions:
#' \code{abc_posterior_bootstrap()}, \code{update_config_from_posterior()},
#' and \code{run_simulation()}.
#'
#' @details
#' This wrapper is mainly a teaching tool. It provides a compact end-to-end
#' posterior predictive workflow, but it intentionally hides several modeling
#' choices by collapsing the posterior to a single summary and then simulating
#' from that reduced representation.
#'
#' For more serious work, manual posterior predictive simulation is preferred.
#' The recommended workflow is to draw posterior parameter values explicitly
#' with \code{abc_posterior_bootstrap()}, inspect or modify those draws as
#' needed, rebuild a simulation configuration explicitly with
#' \code{\link{new_simulation_config}} so the parameter structure is fully under
#' your control, run the simulation with \code{run_simulation()}, and then
#' compare the simulated output with the observed data using plotting or
#' summary functions. \code{update_config_from_posterior()} can still be useful
#' for quick checks, but rebuilding the config is the safer option when you
#' need to know exactly how posterior values are mapped back into the model.
#' Following the steps manually makes each assumption visible, including which
#' posterior draw was used, how parameter values entered the simulation config,
#' and how the posterior predictive data were generated.
#'
#' @param config Simulation configuration object.
#' @param abc_result Fitted object from \code{abc_abc()}.
#' @param observed_df Observed trial-level data frame.
#' @param n_conditions Number of posterior predictive conditions.
#' @param n_trials_per_condition Number of trials per condition.
#' @param n_items Number of items per trial.
#' @param n_conditions_per_chunk Number of conditions per processing chunk.
#' @param output_dir Optional output directory for simulation files.
#' @param rt_facet_x Facet columns for \code{plot_rt()} x facets.
#' @param rt_facet_y Facet columns for \code{plot_rt()} y facets.
#' @param accuracy_x Grouping variable for \code{plot_accuracy()} x-axis.
#' @param accuracy_facet_x Facet columns for \code{plot_accuracy()} x facets.
#' @param accuracy_facet_y Facet columns for \code{plot_accuracy()} y facets.
#' @return \code{invisible(NULL)}. This function is used for plotting side
#'   effects only and prints RT and accuracy plots directly.
#' @examples
#' \donttest{
#' # Load example simulation config, fitted ABC model, and observed data
#' base_dir <- system.file("extdata", "rdm_minimal", package = "eam")
#' sim_output <- load_simulation_output(file.path(base_dir, "simulation"))
#' abc_model <- readRDS(file.path(base_dir, "abc", "abc_neuralnet_model.rds"))
#' obs_df <- read.csv(file.path(base_dir, "observation", "observation_data.csv"))
#'
#' # Run a high-level posterior predictive check
#' abc_posterior_predictive_check(
#'   config = sim_output$simulation_config,
#'   abc_result = abc_model,
#'   observed_df = obs_df,
#'   n_conditions = 1,
#'   n_trials_per_condition = 500,
#'   rt_facet_x = c("item_idx"),
#'   rt_facet_y = c(),
#'   accuracy_x = "item_idx",
#'   accuracy_facet_x = c("group"),
#'   accuracy_facet_y = c()
#' )
#' }
#' @export
abc_posterior_predictive_check <- function(
    config,
    abc_result,
    observed_df,
    n_conditions = 1,
    n_trials_per_condition = 500,
    n_items = config$n_items,
    n_conditions_per_chunk = NULL,
    output_dir = NULL,
    rt_facet_x = c("item_idx"),
    rt_facet_y = c(),
    accuracy_x = "item_idx",
    accuracy_facet_x = c(),
    accuracy_facet_y = c()) {
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be an eam_simulation_config object")
  }
  if (!inherits(abc_result, "abc")) {
    stop("abc_result must be an object of class 'abc'")
  }
  if (!is.data.frame(observed_df)) {
    stop("observed_df must be a data frame")
  }

  abc_params <- as.data.frame(extract_abc_param_values(abc_result))
  if (ncol(abc_params) == 0L) {
    stop("abc_result does not contain posterior parameter columns")
  }

  med <- vapply(abc_params, stats::median, numeric(1L), na.rm = TRUE)
  posterior_params <- as.data.frame(as.list(med), stringsAsFactors = FALSE)

  posterior_predictive_check.run_from_params(
    config = config,
    posterior_params = posterior_params,
    observed_df = observed_df,
    source_type = "abc_median",
    n_conditions = n_conditions,
    n_trials_per_condition = n_trials_per_condition,
    n_items = n_items,
    n_conditions_per_chunk = n_conditions_per_chunk,
    output_dir = output_dir,
    rt_facet_x = rt_facet_x,
    rt_facet_y = rt_facet_y,
    accuracy_x = accuracy_x,
    accuracy_facet_x = accuracy_facet_x,
    accuracy_facet_y = accuracy_facet_y
  )
}


#' ABI posterior predictive check
#'
#' High-level convenience wrapper for posterior predictive checks from
#' ABI-trained estimators.
#'
#' This function is for teaching and quick demonstrations.
#' It is intentionally specific to one estimator workflow at a time,
#' selected by \code{estimator_type}.
#' For step checks, follow these functions:
#' \code{abi_estimate()} or \code{abi_sample_posterior()}, then
#' \code{update_config_from_posterior()}, and \code{run_simulation()}.
#'
#' @details
#' This wrapper is mainly a teaching tool. It provides a compact end-to-end
#' posterior predictive workflow for ABI, but it intentionally hides several
#' modeling choices behind a single helper call.
#'
#' For more serious work, manual posterior predictive simulation is preferred.
#' The recommended workflow is to obtain parameter values explicitly with
#' \code{abi_estimate()} for point estimators or \code{abi_sample_posterior()}
#' for posterior estimators, inspect or summarise those values, rebuild a
#' simulation configuration explicitly with \code{\link{new_simulation_config}}
#' so the parameter structure is fully under your control, run the simulation
#' with \code{run_simulation()}, and then compare simulated and observed data
#' using plotting or summary functions. \code{update_config_from_posterior()}
#' can still be useful for quick checks, but rebuilding the config is the
#' safer option when you need to know exactly how inferred values are mapped
#' back into the model. Following the steps manually makes each assumption
#' visible, including which ABI output was used, how posterior summaries were
#' constructed, and how the posterior predictive data were generated.
#'
#' @param config Simulation configuration object.
#' @param trained_estimator Trained ABI estimator from \code{abi_train()}.
#' @param estimator_type Character string: \code{"point"} or \code{"posterior"}.
#' @param observed_df Observed trial-level data frame.
#' @param Z Input data for ABI estimation/sampling. If \code{NULL}, uses \code{Z_test}.
#' @param posterior_dataset_id Dataset id used when \code{estimator_type = "posterior"}.
#' @param posterior_n_samples Number of samples when \code{estimator_type = "posterior"}.
#' @param n_conditions Number of posterior predictive conditions.
#' @param n_trials_per_condition Number of trials per condition.
#' @param n_items Number of items per trial.
#' @param n_conditions_per_chunk Number of conditions per processing chunk.
#' @param output_dir Optional output directory for simulation files.
#' @param rt_facet_x Facet columns for \code{plot_rt()} x facets.
#' @param rt_facet_y Facet columns for \code{plot_rt()} y facets.
#' @param accuracy_x Grouping variable for \code{plot_accuracy()} x-axis.
#' @param accuracy_facet_x Facet columns for \code{plot_accuracy()} x facets.
#' @param accuracy_facet_y Facet columns for \code{plot_accuracy()} y facets.
#' @return \code{invisible(NULL)}. This function is used for plotting side
#'   effects only and prints RT and accuracy plots directly.
#' @examples
#' \dontrun{
#' # Load an observed dataset and a trained ABI estimator prepared in your environment
#' observed_data <- sim_output$open_dataset() |>
#'   dplyr::filter(chunk_idx == 1, condition_idx == 1) |>
#'   dplyr::collect()
#'
#' # Point-estimate workflow
#' abi_posterior_predictive_check(
#'   config = sim_config,
#'   trained_estimator = trained_point_estimator,
#'   estimator_type = "point",
#'   observed_df = observed_data,
#'   Z = abi_input$Z_test[[1]],
#'   rt_facet_x = c("item_idx"),
#'   rt_facet_y = c(),
#'   accuracy_x = "item_idx",
#'   accuracy_facet_x = c("ndt_beta_0"),
#'   accuracy_facet_y = c()
#' )
#'
#' # Posterior-sampling workflow
#' abi_posterior_predictive_check(
#'   config = sim_config,
#'   trained_estimator = trained_posterior_estimator,
#'   estimator_type = "posterior",
#'   observed_df = observed_data,
#'   Z = abi_input$Z_test,
#'   posterior_dataset_id = 1,
#'   posterior_n_samples = 1000,
#'   rt_facet_x = c("item_idx"),
#'   rt_facet_y = c(),
#'   accuracy_x = "item_idx",
#'   accuracy_facet_x = c("ndt_beta_0"),
#'   accuracy_facet_y = c()
#' )
#' }
#' @export
abi_posterior_predictive_check <- function(
    config,
    trained_estimator,
    estimator_type = c("point", "posterior"),
    observed_df,
    Z = NULL,
    posterior_dataset_id = 1,
    posterior_n_samples = 1000,
    n_conditions = 1,
    n_trials_per_condition = 500,
    n_items = config$n_items,
    n_conditions_per_chunk = NULL,
    output_dir = NULL,
    rt_facet_x = c("item_idx"),
    rt_facet_y = c(),
    accuracy_x = "item_idx",
    accuracy_facet_x = c(),
    accuracy_facet_y = c()) {
  if (!inherits(config, "eam_simulation_config")) {
    stop("config must be an eam_simulation_config object")
  }
  if (!inherits(trained_estimator, "eam_abi_trained_estimator")) {
    stop("trained_estimator must be an object of class 'eam_abi_trained_estimator'")
  }
  if (!is.data.frame(observed_df)) {
    stop("observed_df must be a data frame")
  }

  estimator_type <- match.arg(estimator_type)

  if (is.null(Z)) {
    Z <- trained_estimator$abi_input$Z_test
  }

  if (estimator_type == "point") {
    point_est <- abi_estimate(
      trained_estimator = trained_estimator,
      Z = Z
    )

    if (is.null(rownames(point_est))) {
      stop("abi_estimate output has no parameter names (rownames)")
    }

    posterior_params <- as.data.frame(
      as.list(stats::setNames(as.vector(point_est[, 1]), rownames(point_est))),
      stringsAsFactors = FALSE
    )
    source_type <- "abi_point"
  } else {
    posterior_samples <- abi_sample_posterior(
      trained_estimator = trained_estimator,
      Z = Z,
      N = posterior_n_samples
    )

    if (!"dataset_id" %in% names(posterior_samples)) {
      stop("abi_sample_posterior output must contain column 'dataset_id'")
    }

    dataset_samples <- posterior_samples[posterior_samples$dataset_id == posterior_dataset_id, , drop = FALSE]
    if (nrow(dataset_samples) == 0L) {
      stop("No posterior samples found for posterior_dataset_id = ", posterior_dataset_id)
    }

    param_cols <- setdiff(names(dataset_samples), "dataset_id")
    if (length(param_cols) == 0L) {
      stop("No parameter columns found in ABI posterior samples")
    }

    med <- vapply(dataset_samples[param_cols], stats::median, numeric(1L), na.rm = TRUE)
    posterior_params <- as.data.frame(as.list(med), stringsAsFactors = FALSE)
    source_type <- "abi_posterior_median"
  }

  posterior_predictive_check.run_from_params(
    config = config,
    posterior_params = posterior_params,
    observed_df = observed_df,
    source_type = source_type,
    n_conditions = n_conditions,
    n_trials_per_condition = n_trials_per_condition,
    n_items = n_items,
    n_conditions_per_chunk = n_conditions_per_chunk,
    output_dir = output_dir,
    rt_facet_x = rt_facet_x,
    rt_facet_y = rt_facet_y,
    accuracy_x = accuracy_x,
    accuracy_facet_x = accuracy_facet_x,
    accuracy_facet_y = accuracy_facet_y
  )
}


#' @keywords internal
posterior_predictive_check.run_from_params <- function(
    config,
    posterior_params,
    observed_df,
    source_type,
    n_conditions,
    n_trials_per_condition,
    n_items,
    n_conditions_per_chunk,
    output_dir,
    rt_facet_x,
    rt_facet_y,
    accuracy_x,
    accuracy_facet_x,
    accuracy_facet_y) {
  post_sim_config <- update_config_from_posterior(
    config = config,
    posterior_params = posterior_params,
    n_conditions_per_chunk = n_conditions_per_chunk,
    n_conditions = n_conditions,
    n_trials_per_condition = n_trials_per_condition,
    n_items = n_items
  )

  post_output <- if (is.null(output_dir)) {
    run_simulation(post_sim_config)
  } else {
    run_simulation(post_sim_config, output_dir = output_dir)
  }

  plot_cols <- posterior_predictive_check.resolve_plot_columns(
    post_output = post_output,
    observed_df = observed_df,
    rt_facet_x = rt_facet_x,
    rt_facet_y = rt_facet_y,
    accuracy_x = accuracy_x,
    accuracy_facet_x = accuracy_facet_x,
    accuracy_facet_y = accuracy_facet_y
  )

  rt_plot <- plot_rt(
    simulated_output = post_output,
    observed_df = observed_df,
    facet_x = plot_cols$rt_facet_x,
    facet_y = plot_cols$rt_facet_y
  )

  # Print plots so they render immediately in R Markdown and interactive use.
  print(rt_plot)

  if (posterior_predictive_check.can_plot_accuracy(post_output, observed_df)) {
    accuracy_plot <- plot_accuracy(
      simulated_output = post_output,
      observed_df = observed_df,
      x = plot_cols$accuracy_x,
      facet_x = plot_cols$accuracy_facet_x,
      facet_y = plot_cols$accuracy_facet_y
    )
    print(accuracy_plot)
  }

  invisible(NULL)
}


#' @keywords internal
posterior_predictive_check.resolve_plot_columns <- function(
    post_output,
    observed_df,
    rt_facet_x,
    rt_facet_y,
    accuracy_x,
    accuracy_facet_x,
    accuracy_facet_y) {
  sim_cols <- colnames(post_output$open_dataset())
  obs_cols <- names(observed_df)
  shared_cols <- intersect(sim_cols, obs_cols)

  keep_shared <- function(x) {
    if (length(x) == 0L) {
      return(character(0L))
    }
    intersect(x, shared_cols)
  }

  rt_facet_x_safe <- keep_shared(rt_facet_x)
  rt_facet_y_safe <- keep_shared(rt_facet_y)
  accuracy_facet_x_safe <- keep_shared(accuracy_facet_x)
  accuracy_facet_y_safe <- keep_shared(accuracy_facet_y)

  if (!accuracy_x %in% shared_cols) {
    fallback_candidates <- c("item_idx", "condition_idx", "group", "choice")
    fallback <- fallback_candidates[fallback_candidates %in% shared_cols]

    if (length(fallback) == 0L) {
      stop(
        "Cannot resolve accuracy_x. Requested '", accuracy_x,
        "' is missing, and no fallback shared between simulated and observed data."
      )
    }
    accuracy_x <- fallback[1L]
  }

  list(
    rt_facet_x = rt_facet_x_safe,
    rt_facet_y = rt_facet_y_safe,
    accuracy_x = accuracy_x,
    accuracy_facet_x = accuracy_facet_x_safe,
    accuracy_facet_y = accuracy_facet_y_safe
  )
}


#' @keywords internal
posterior_predictive_check.can_plot_accuracy <- function(post_output, observed_df) {
  "choice" %in% names(observed_df)
}
