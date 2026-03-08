#' Plot CV parameter recovery
#'
#' Visualize parameter recovery from cross-validation results, showing estimated
#' vs. true parameter values and residual distributions for each parameter.
#'
#' @param data An object containing recovery results. The expected structure
#'   depends on the method dispatched.
#' @param ... Additional arguments passed to class-specific methods.
#'
#' @return Invisibly returns `NULL`. Called for its side effect of producing plots.
#'
#' @seealso
#'   \code{\link{plot_cv_recovery.cv4abc}}, \code{\link{plot_cv_recovery.eam_abi_assess}},
#'   \code{\link{plot_cv_recovery.eam_abi_posterior_samples}}
#'
#' @examples
#' # Load CV output from saved file
#' cv_file <- system.file(
#'   "extdata", "rdm_minimal", "abc", "cv", "neuralnet.rds",
#'   package = "eam"
#' )
#' abc_neuralnet_cv <- readRDS(cv_file)
#'
#' # Plot parameter recovery
#' plot_cv_recovery(
#'   abc_neuralnet_cv,
#'   n_rows = 2,
#'   n_cols = 1,
#'   resid_tol = 0.99
#' )
#'
#' @export
plot_cv_recovery <- function(data, ...) {
  UseMethod("plot_cv_recovery")
}

theme_eam <- ggplot2::theme_minimal() +
  ggplot2::theme(
    plot.title = ggplot2::element_text(hjust = 0.5),
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.line = ggplot2::element_line(color = "black"),
    axis.ticks = ggplot2::element_line(color = "black")
  )

#' @rdname plot_cv_recovery
#' @method plot_cv_recovery cv4abc
#'
#' @param data A \code{cv4abc} object containing true parameters and
#'   cross-validated estimates.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{n_rows}{Integer; number of rows in the plot grid (default: 3)}
#'     \item{n_cols}{Integer; number of columns in the plot grid, multiplied by 2
#'       for paired plots (default: 1)}
#'     \item{method}{Character; smoothing method for \code{geom_smooth} (default: "lm")}
#'     \item{formula}{Formula; used in \code{geom_smooth} (default: y ~ x)}
#'     \item{resid_tol}{Numeric; quantile threshold for filtering residuals by
#'       absolute value. If specified, only observations with residuals below
#'       this quantile are plotted (default: NULL, no filtering)}
#'     \item{interactive}{Logical; whether to pause between pages and wait for
#'       user input (default: FALSE)}
#'   }
#'
#' @export
plot_cv_recovery.cv4abc <- function(data, ...) {
  plot_per_parameter <- 2
  # check the parameters
  dots <- rlang::list2(...)
  n_rows <- dots$n_rows %||% 3
  dots$n_rows <- rlang::zap()
  n_cols <- (dots$n_cols %||% 1) * plot_per_parameter
  dots$n_cols <- rlang::zap()
  method <- dots$method %||% "lm"
  dots$method <- rlang::zap()
  formula <- dots$formula %||% (y ~ x)
  dots$formula <- rlang::zap()
  resid_tol <- dots$resid_tol %||% NULL
  dots$resid_tol <- rlang::zap()
  interactive <- dots$interactive %||% FALSE
  dots$interactive <- rlang::zap()

  # dim check
  n_tols <- length(data$tols)
  n_params <- ncol(data$true)
  plots_per_tol <- n_params * plot_per_parameter
  plots_per_page <- n_rows * n_cols

  # Get parameter names
  param_names <- data$names$parameter.names
  if (is.null(param_names)) {
    param_names <- paste0("param_", 1:n_params)
  }

  # Get tolerance names from data$estim
  tol_names <- names(data$estim)

  # Loop through each tolerance level
  for (i in 1:n_tols) {
    tol_name <- tol_names[i]

    # Get estimates for this tolerance
    estimates <- data$estim[[tol_name]]

    # Create list to store plots for this tolerance
    tol_plot_list <- list()
    plot_idx <- 1

    # Loop through each parameter
    for (j in 1:n_params) {
      param_name <- param_names[j]

      # Prepare data for plotting
      true_vals <- data$true[, j]
      est_vals <- estimates[, j]
      residuals <- est_vals - true_vals

      # Filter by residual tolerance if specified
      if (!is.null(resid_tol)) {
        threshold <- stats::quantile(abs(residuals), resid_tol, na.rm = TRUE)
        keep_idx <- abs(residuals) <= threshold
        true_vals <- true_vals[keep_idx]
        est_vals <- est_vals[keep_idx]
        residuals <- residuals[keep_idx]
      }

      # Calculate correlation
      cor_value <- stats::cor(true_vals, est_vals, use = "complete.obs")

      # NSE variable bindings for R CMD check
      true <- estimate <- residual <- NULL
      
      plot_df <- data.frame(
        true = true_vals,
        estimate = est_vals,
        residual = residuals
      )

      # Plot 1: Estimate vs True
      p1 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = true, y = estimate)) +
        ggplot2::geom_point() +
        ggplot2::geom_abline(
          intercept = 0,
          slope = 1,
          linetype = "dashed",
          color = "red",
          alpha = 0.5
        ) +
        ggplot2::geom_smooth(
          method = method,
          formula = formula,
          se = FALSE,
          color = scales::alpha("blue", 0.5),
          alpha = 0.5,
          linewidth = 0.8
        ) +
        ggplot2::labs(
          title = paste0(param_name),
          x = "True",
          y = "Estimated"
        ) +
        ggplot2::annotate(
          "text",
          x = -Inf,
          y = Inf,
          label = sprintf("r = %.4f", cor_value),
          hjust = -0.1,
          vjust = 1.5,
          size = 3
        ) +
        theme_eam

      # Plot 2: Density of residuals (estimate - true)
      p2 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = residual)) +
        ggplot2::geom_density(
          color = "blue",
        ) +
        ggplot2::geom_vline(
          xintercept = 0,
          linetype = "dashed",
          color = "red",
          alpha = 0.5
        ) +
        ggplot2::labs(
          title = paste0("Residuals"),
          x = "Estimate - True",
          y = "Density"
        ) +
        theme_eam


      # Add plots to list for this tolerance
      tol_plot_list[[plot_idx]] <- p1
      tol_plot_list[[plot_idx + 1]] <- p2
      plot_idx <- plot_idx + plot_per_parameter
    }

    # Calculate pages needed for this tolerance
    n_pages_tol <- ceiling(plots_per_tol / plots_per_page)

    # Render pages for this tolerance
    for (page in 1:n_pages_tol) {
      start_idx <- (page - 1) * plots_per_page + 1
      end_idx <- min(page * plots_per_page, plots_per_tol)

      page_plots <- tol_plot_list[start_idx:end_idx]

      # Arrange plots for this page
      gridExtra::grid.arrange(
        grobs = page_plots,
        ncol = n_cols,
        nrow = n_rows,
        top = grid::textGrob(
          paste0(tol_name, " (page ", page, "/", n_pages_tol, ")"),
          gp = grid::gpar(fontsize = 16, fontface = "bold")
        )
      )

      # interactive mode
      if (interactive) {
        readline(prompt = "Press [Enter] to continue to the next page...")
      }
    }
  }

  invisible(NULL)
}

#' @rdname plot_cv_recovery
#' @method plot_cv_recovery eam_abi_assess
#'
#' @param data An \code{eam_abi_assess} object from \code{\link{abi_assess}}
#'   containing recovery results with an \code{estimates} element. The
#'   \code{estimates} element must be a data frame with columns
#'   \code{parameter}, \code{estimate}, and \code{truth}.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{n_rows}{Integer; number of rows in the plot grid (default: 3)}
#'     \item{n_cols}{Integer; number of columns in the plot grid, multiplied by 2
#'       for paired plots (default: 1)}
#'     \item{method}{Character; smoothing method for \code{geom_smooth} (default: "lm")}
#'     \item{formula}{Formula; used in \code{geom_smooth} (default: y ~ x)}
#'     \item{resid_tol}{Numeric; quantile threshold for filtering residuals by
#'       absolute value. If specified, only observations with residuals below
#'       this quantile are plotted (default: NULL, no filtering)}
#'     \item{interactive}{Logical; whether to pause between pages and wait for
#'       user input (default: FALSE)}
#'   }
#'
#' @export
plot_cv_recovery.eam_abi_assess <- function(data, ...) {
  # Validate input structure
  if (!"estimates" %in% names(data)) {
    stop("data must contain 'estimates' element")
  }

  estimates_df <- data$estimates

  if (!is.data.frame(estimates_df)) {
    stop("data$estimates must be a data.frame")
  }

  required_cols <- c("parameter", "estimate", "truth")
  missing_cols <- setdiff(required_cols, names(estimates_df))
  if (length(missing_cols) > 0) {
    stop(paste0(
      "data$estimates must contain columns: ",
      paste(missing_cols, collapse = ", ")
    ))
  }

  # Extract parameters
  dots <- rlang::list2(...)
  n_rows <- dots$n_rows %||% 3
  dots$n_rows <- rlang::zap()
  n_cols <- dots$n_cols %||% 1
  dots$n_cols <- rlang::zap()
  method <- dots$method %||% "lm"
  dots$method <- rlang::zap()
  formula <- dots$formula %||% (y ~ x)
  dots$formula <- rlang::zap()
  resid_tol <- dots$resid_tol %||% NULL
  dots$resid_tol <- rlang::zap()
  interactive <- dots$interactive %||% FALSE
  dots$interactive <- rlang::zap()

  # Get unique parameter names for plotting
  param_names <- unique(estimates_df$parameter)
  n_params <- length(param_names)

  # Calculate plot dimensions
  plot_per_parameter <- 2
  n_cols <- n_cols * plot_per_parameter
  plots_per_page <- n_rows * n_cols
  n_pages <- ceiling(n_params * plot_per_parameter / plots_per_page)

  # NSE variable bindings for R CMD check
  true <- estimate <- residual <- NULL

  # Create list to store plots
  plot_list <- list()
  plot_idx <- 1

  # Loop through each parameter
  for (i in seq_along(param_names)) {
    param_name <- param_names[i]

    # Filter data for this parameter
    param_data <- estimates_df[estimates_df$parameter == param_name, ]

    # Calculate residuals
    residuals <- param_data$estimate - param_data$truth

    # Filter by residual tolerance if specified
    if (!is.null(resid_tol)) {
      threshold <- stats::quantile(abs(residuals), resid_tol, na.rm = TRUE)
      keep_idx <- abs(residuals) <= threshold
      param_data <- param_data[keep_idx, ]
      residuals <- residuals[keep_idx]
    }

    # Calculate correlation
    cor_value <- stats::cor(
      param_data$truth,
      param_data$estimate,
      use = "complete.obs"
    )

    # Prepare plot data
    plot_df <- data.frame(
      true = param_data$truth,
      estimate = param_data$estimate,
      residual = residuals
    )

    # Plot 1: Estimate vs True
    p1 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = true, y = estimate)) +
      ggplot2::geom_point() +
      ggplot2::geom_abline(
        intercept = 0,
        slope = 1,
        linetype = "dashed",
        color = "red",
        alpha = 0.5
      ) +
      ggplot2::geom_smooth(
        method = method,
        formula = formula,
        se = FALSE,
        color = scales::alpha("blue", 0.5),
        alpha = 0.5,
        linewidth = 0.8
      ) +
      ggplot2::labs(
        title = paste0(param_name),
        x = "True",
        y = "Estimated"
      ) +
      ggplot2::annotate(
        "text",
        x = -Inf,
        y = Inf,
        label = sprintf("r = %.4f", cor_value),
        hjust = -0.1,
        vjust = 1.5,
        size = 3
      ) +
      theme_eam

    # Plot 2: Density of residuals (estimate - true)
    p2 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = residual)) +
      ggplot2::geom_density(
        color = "blue",
      ) +
      ggplot2::geom_vline(
        xintercept = 0,
        linetype = "dashed",
        color = "red",
        alpha = 0.5
      ) +
      ggplot2::labs(
        title = paste0("Residuals"),
        x = "Estimate - True",
        y = "Density"
      ) +
      theme_eam

    # Add plots to list
    plot_list[[plot_idx]] <- p1
    plot_list[[plot_idx + 1]] <- p2
    plot_idx <- plot_idx + plot_per_parameter
  }

  # Render pages
  for (page in 1:n_pages) {
    start_idx <- (page - 1) * plots_per_page + 1
    end_idx <- min(page * plots_per_page, length(plot_list))

    page_plots <- plot_list[start_idx:end_idx]

    # Arrange plots for this page
    gridExtra::grid.arrange(
      grobs = page_plots,
      ncol = n_cols,
      nrow = n_rows,
      top = grid::textGrob(
        paste0("Recovery (page ", page, "/", n_pages, ")"),
        gp = grid::gpar(fontsize = 16, fontface = "bold")
      )
    )

    # interactive mode
    if (interactive) {
      readline(prompt = "Press [Enter] to continue to the next page...")
    }
  }

  invisible(NULL)
}

#' @rdname plot_cv_recovery
#' @method plot_cv_recovery eam_abi_posterior_samples
#'
#' @param data An \code{eam_abi_posterior_samples} object from
#'   \code{\link{abi_sample_posterior}} containing posterior samples with columns
#'   \code{dataset_id} and parameter columns. The median of each parameter for
#'   each dataset is used as the point estimate for recovery assessment.
#' @param trained_estimator Optional. A trained estimator object returned by
#'   \code{\link{abi_train}}. If provided, the true parameter values are extracted
#'   from \code{trained_estimator$abi_input$theta_test}. Either \code{trained_estimator}
#'   or \code{theta} must be provided, but not both.
#' @param theta Optional. A matrix of true parameter values with parameters as rows
#'   and datasets as columns. Column count must match the number of unique
#'   \code{dataset_id} values in \code{data}. Either \code{trained_estimator} or
#'   \code{theta} must be provided, but not both.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{n_rows}{Integer; number of rows in the plot grid (default: 3)}
#'     \item{n_cols}{Integer; number of columns in the plot grid, multiplied by 2
#'       for paired plots (default: 1)}
#'     \item{method}{Character; smoothing method for \code{geom_smooth} (default: "lm")}
#'     \item{formula}{Formula; used in \code{geom_smooth} (default: y ~ x)}
#'     \item{resid_tol}{Numeric; quantile threshold for filtering residuals by
#'       absolute value. If specified, only observations with residuals below
#'       this quantile are plotted (default: NULL, no filtering)}
#'     \item{interactive}{Logical; whether to pause between pages and wait for
#'       user input (default: FALSE)}
#'   }
#'
#' @examples
#' \dontrun{
#' # Train a posterior estimator
#' trained_estimator <- abi_train(
#'   estimator = posterior_estimator,
#'   abi_input = abi_input,
#'   epochs = 50
#' )
#'
#' # Sample from posterior using test data (default)
#' posterior_samples <- abi_sample_posterior(
#'   trained_estimator = trained_estimator,
#'   N = 1000
#' )
#'
#' # Plot recovery using trained_estimator to get true values
#' plot_cv_recovery(
#'   posterior_samples,
#'   trained_estimator = trained_estimator
#' )
#'
#' # Alternatively, provide true parameter values directly
#' plot_cv_recovery(
#'   posterior_samples,
#'   theta = abi_input$theta_test
#' )
#' }
#'
#' @export
plot_cv_recovery.eam_abi_posterior_samples <- function(
    data,
    trained_estimator = NULL,
    theta = NULL,
    ...) {
  # Validate that exactly one of trained_estimator or theta is provided
  if (is.null(trained_estimator) && is.null(theta)) {
    stop("Either 'trained_estimator' or 'theta' must be provided")
  }

  if (!is.null(trained_estimator) && !is.null(theta)) {
    stop("Only one of 'trained_estimator' or 'theta' should be provided, not both")
  }

  # Validate data structure
  if (!"dataset_id" %in% names(data)) {
    stop("data must contain a 'dataset_id' column")
  }

  # Get parameter names (exclude dataset_id)
  param_names <- setdiff(names(data), "dataset_id")

  if (length(param_names) == 0) {
    stop("No parameter columns found in data")
  }

  # Get unique dataset IDs
  dataset_ids <- sort(unique(data$dataset_id))
  n_datasets <- length(dataset_ids)

  # Calculate median estimates for each parameter and dataset
  estimates_list <- list()

  for (dataset_id in dataset_ids) {
    dataset_data <- data[data$dataset_id == dataset_id, ]

    for (param in param_names) {
      values <- dataset_data[[param]]
      median_val <- stats::median(values, na.rm = TRUE)

      estimates_list[[length(estimates_list) + 1]] <- list(
        dataset_id = dataset_id,
        parameter = param,
        estimate = median_val
      )
    }
  }

  estimates_df <- dplyr::bind_rows(estimates_list)

  # Extract true parameter values
  if (!is.null(trained_estimator)) {
    # Validate trained_estimator
    if (!inherits(trained_estimator, "eam_abi_trained_estimator")) {
      stop("trained_estimator must be an object of class 'eam_abi_trained_estimator'")
    }

    if (!"abi_input" %in% names(trained_estimator)) {
      stop("trained_estimator must contain 'abi_input' element")
    }

    abi_input <- trained_estimator$abi_input

    if (!"theta_test" %in% names(abi_input)) {
      stop("trained_estimator$abi_input must contain 'theta_test' element")
    }

    theta_test <- abi_input$theta_test

    # Validate dimensions
    if (!is.matrix(theta_test)) {
      stop("trained_estimator$abi_input$theta_test must be a matrix")
    }

    if (ncol(theta_test) != n_datasets) {
      stop(sprintf(
        "Number of datasets in theta_test (%d) does not match number of unique dataset_ids (%d)",
        ncol(theta_test),
        n_datasets
      ))
    }

    # Check parameter names match
    theta_param_names <- rownames(theta_test)
    if (is.null(theta_param_names)) {
      stop("theta_test must have row names matching parameter names")
    }

    missing_params <- setdiff(param_names, theta_param_names)
    if (length(missing_params) > 0) {
      stop(paste0(
        "Parameters in data not found in theta_test: ",
        paste(missing_params, collapse = ", ")
      ))
    }

    # Extract true values and add to estimates_df
    truth_values <- numeric(nrow(estimates_df))

    for (i in seq_len(nrow(estimates_df))) {
      dataset_idx <- which(dataset_ids == estimates_df$dataset_id[i])
      param_name <- estimates_df$parameter[i]
      param_idx <- which(theta_param_names == param_name)

      truth_values[i] <- theta_test[param_idx, dataset_idx]
    }

    estimates_df$truth <- truth_values
  } else {
    # Use provided theta matrix
    if (!is.matrix(theta)) {
      stop("theta must be a matrix")
    }

    if (ncol(theta) != n_datasets) {
      stop(sprintf(
        "Number of columns in theta (%d) does not match number of unique dataset_ids (%d)",
        ncol(theta),
        n_datasets
      ))
    }

    # Check parameter names match
    theta_param_names <- rownames(theta)
    if (is.null(theta_param_names)) {
      stop("theta must have row names matching parameter names")
    }

    missing_params <- setdiff(param_names, theta_param_names)
    if (length(missing_params) > 0) {
      stop(paste0(
        "Parameters in data not found in theta: ",
        paste(missing_params, collapse = ", ")
      ))
    }

    # Extract true values and add to estimates_df
    truth_values <- numeric(nrow(estimates_df))

    for (i in seq_len(nrow(estimates_df))) {
      dataset_idx <- which(dataset_ids == estimates_df$dataset_id[i])
      param_name <- estimates_df$parameter[i]
      param_idx <- which(theta_param_names == param_name)

      truth_values[i] <- theta[param_idx, dataset_idx]
    }

    estimates_df$truth <- truth_values
  }

  # Now use the same plotting logic as plot_cv_recovery.eam_abi_assess
  # Extract parameters
  dots <- rlang::list2(...)
  n_rows <- dots$n_rows %||% 3
  dots$n_rows <- rlang::zap()
  n_cols <- dots$n_cols %||% 1
  dots$n_cols <- rlang::zap()
  method <- dots$method %||% "lm"
  dots$method <- rlang::zap()
  formula <- dots$formula %||% (y ~ x)
  dots$formula <- rlang::zap()
  resid_tol <- dots$resid_tol %||% NULL
  dots$resid_tol <- rlang::zap()
  interactive <- dots$interactive %||% FALSE
  dots$interactive <- rlang::zap()

  # Get unique parameter names for plotting
  param_names_plot <- unique(estimates_df$parameter)
  n_params <- length(param_names_plot)

  # Calculate plot dimensions
  plot_per_parameter <- 2
  n_cols <- n_cols * plot_per_parameter
  plots_per_page <- n_rows * n_cols
  n_pages <- ceiling(n_params * plot_per_parameter / plots_per_page)

  # NSE variable bindings for R CMD check
  true <- estimate <- residual <- NULL

  # Create list to store plots
  plot_list <- list()
  plot_idx <- 1

  # Loop through each parameter
  for (i in seq_along(param_names_plot)) {
    param_name <- param_names_plot[i]

    # Filter data for this parameter
    param_data <- estimates_df[estimates_df$parameter == param_name, ]

    # Calculate residuals
    residuals <- param_data$estimate - param_data$truth

    # Filter by residual tolerance if specified
    if (!is.null(resid_tol)) {
      threshold <- stats::quantile(abs(residuals), resid_tol, na.rm = TRUE)
      keep_idx <- abs(residuals) <= threshold
      param_data <- param_data[keep_idx, ]
      residuals <- residuals[keep_idx]
    }

    # Calculate correlation
    cor_value <- stats::cor(
      param_data$truth,
      param_data$estimate,
      use = "complete.obs"
    )

    # Prepare plot data
    plot_df <- data.frame(
      true = param_data$truth,
      estimate = param_data$estimate,
      residual = residuals
    )

    # Plot 1: Estimate vs True
    p1 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = true, y = estimate)) +
      ggplot2::geom_point() +
      ggplot2::geom_abline(
        intercept = 0,
        slope = 1,
        linetype = "dashed",
        color = "red",
        alpha = 0.5
      ) +
      ggplot2::geom_smooth(
        method = method,
        formula = formula,
        se = FALSE,
        color = scales::alpha("blue", 0.5),
        alpha = 0.5,
        linewidth = 0.8
      ) +
      ggplot2::labs(
        title = paste0(param_name),
        x = "True",
        y = "Estimated"
      ) +
      ggplot2::annotate(
        "text",
        x = -Inf,
        y = Inf,
        label = sprintf("r = %.4f", cor_value),
        hjust = -0.1,
        vjust = 1.5,
        size = 3
      ) +
      theme_eam

    # Plot 2: Density of residuals (estimate - true)
    p2 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = residual)) +
      ggplot2::geom_density(
        color = "blue",
      ) +
      ggplot2::geom_vline(
        xintercept = 0,
        linetype = "dashed",
        color = "red",
        alpha = 0.5
      ) +
      ggplot2::labs(
        title = paste0("Residuals"),
        x = "Estimate - True",
        y = "Density"
      ) +
      theme_eam

    # Add plots to list
    plot_list[[plot_idx]] <- p1
    plot_list[[plot_idx + 1]] <- p2
    plot_idx <- plot_idx + plot_per_parameter
  }

  # Render pages
  for (page in 1:n_pages) {
    start_idx <- (page - 1) * plots_per_page + 1
    end_idx <- min(page * plots_per_page, length(plot_list))

    page_plots <- plot_list[start_idx:end_idx]

    # Arrange plots for this page
    gridExtra::grid.arrange(
      grobs = page_plots,
      ncol = n_cols,
      nrow = n_rows,
      top = grid::textGrob(
        paste0("Posterior Recovery (page ", page, "/", n_pages, ")"),
        gp = grid::gpar(fontsize = 16, fontface = "bold")
      )
    )

    # interactive mode
    if (interactive) {
      readline(prompt = "Press [Enter] to continue to the next page...")
    }
  }

  invisible(NULL)
}
