#' ABC with resampling
#'
#' Performs ABC inference with resampling to assess stability and uncertainty.
#' Each iteration draws a random sample from the simulation pool and runs ABC,
#' producing multiple posterior estimates for comparison.
#'
#' @param target Target summary statistics from observed data
#' @param param Parameter values matrix or data frame
#' @param sumstat Summary statistics matrix or data frame
#' @param n_iterations Number of resample iterations
#' @param n_samples Number of samples to draw in each iteration
#' @param replace Logical, whether to sample with replacement (default FALSE)
#' @param ... Additional arguments passed to abc::abc
#'
#' @examples
#' # Load ABC input data from example simulation
#' abc_input <- readRDS(
#'   system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
#' )
#'
#' # Perform ABC resampling
#' results <- abc_resample(
#'   target = abc_input$target,
#'   param = abc_input$param,
#'   sumstat = abc_input$sumstat,
#'   n_iterations = 2,
#'   n_samples = 2,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#'
#' # check the abc results
#' str(results)
#' @export
abc_resample <- function(
    target,
    param,
    sumstat,
    n_iterations,
    n_samples,
    replace = FALSE,
    ...) {
  # Validate inputs
  if (nrow(param) != nrow(sumstat)) {
    stop("param and sumstat must have the same number of rows")
  }

  total_rows <- nrow(param)

  # Check sample size constraints
  if (!replace && n_samples > total_rows) {
    stop("When replace = FALSE,
    n_samples cannot be larger than the number of available rows")
  }

  if (replace && n_samples > total_rows) {
    warning("n_samples is larger than available rows;
    sampling with replacement")
  }

  # Store results
  results <- vector("list", n_iterations)

  # Perform bootstrap iterations
  for (i in seq_len(n_iterations)) {
    # Draw random sample indices
    sample_idx <- sample(total_rows, n_samples, replace = replace)

    # Subset param and sumstat
    param_boot <- param[sample_idx, , drop = FALSE]
    sumstat_boot <- sumstat[sample_idx, , drop = FALSE]

    # Call abc::abc with bootstrapped data
    results[[i]] <- abc::abc(
      target = target,
      param = param_boot,
      sumstat = sumstat_boot,
      ...
    )
  }

  results
}

#' Extract parameter values from abc result
#'
#' @param abc_result Single abc result object
#' @return Matrix of parameter values
#' @keywords internal
extract_abc_param_values <- function(abc_result) {
  if (!is.null(abc_result$adj.values)) {
    return(abc_result$adj.values)
  }

  if (!is.null(abc_result$unadj.values)) {
    return(abc_result$unadj.values)
  }

  stop("abc result must contain either adj.values or unadj.values")
}

#' Extract posterior medians from abc_resample output
#'
#' Internal helper to compute parameter medians across abc_resample iterations.
#'
#' @param resample_results List of abc results from abc_resample
#' @return Matrix where each row is an iteration and each column is parameter median
#' @keywords internal
extract_resample_medians <- function(resample_results) {
  # Guard: check if input is a valid list
  if (!is.list(resample_results) || length(resample_results) == 0) {
    stop("resample_results must be a non-empty list of abc results")
  }

  # Guard: check if first element looks like abc result
  first_model <- resample_results[[1]]
  if (is.null(first_model$adj.values) && is.null(first_model$unadj.values)) {
    stop("abc result must contain either adj.values or unadj.values")
  }

  # Get structure from first iteration
  param_matrix <- extract_abc_param_values(first_model)
  n_params <- ncol(param_matrix)
  n_iterations <- length(resample_results)

  # Get parameter names
  param_names <- colnames(param_matrix)
  if (is.null(param_names)) {
    param_names <- paste0("param_", 1:n_params)
  }

  # Collect medians from all iterations
  medians_matrix <- matrix(NA, nrow = n_iterations, ncol = n_params)
  colnames(medians_matrix) <- param_names

  for (i in seq_len(n_iterations)) {
    param_vals <- extract_abc_param_values(resample_results[[i]])
    medians_matrix[i, ] <- apply(param_vals, 2, stats::median, na.rm = TRUE)
  }

  medians_matrix
}

#' Plot resample median distributions
#'
#' Plot density distributions of parameter medians across resample iterations.
#'
#' @param data List of abc results from abc_resample
#' @param n_rows Number of rows in plot grid (default 2)
#' @param n_cols Number of columns in plot grid (default 2)
#' @param interactive Whether to pause between pages (default FALSE)
#'
#' @examples
#' \dontrun{
#' # Load ABC input data from example simulation
#' abc_input <- readRDS(
#'   system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
#' )
#'
#' # Perform ABC resampling
#' results <- abc_resample(
#'   target = abc_input$target,
#'   param = abc_input$param,
#'   sumstat = abc_input$sumstat,
#'   n_iterations = 100,
#'   n_samples = 100,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#' 
#' # plot the resample medians for each parameter
#' plot_resample_medians(results)
#' }
#' @export
plot_resample_medians <- function(
    data,
    n_rows = 2,
    n_cols = 2,
    interactive = FALSE) {
  # Validate input: should be a list of abc results
  if (!is.list(data) || length(data) == 0) {
    stop("data must be a non-empty list of abc results from abc_resample")
  }

  # Extract medians from all iterations
  medians_matrix <- extract_resample_medians(data)
  n_params <- ncol(medians_matrix)
  param_names <- colnames(medians_matrix)

  plots_per_page <- n_rows * n_cols
  n_pages <- ceiling(n_params / plots_per_page)

  # NSE variable bindings for R CMD check
  value <- NULL

  # Create plots for each parameter
  plot_list <- list()
  for (j in 1:n_params) {
    param_name <- param_names[j]

    # Prepare data for plotting
    plot_df <- data.frame(
      value = medians_matrix[, j]
    )

    # Create density plot
    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = value)) +
      ggplot2::geom_density(
        alpha = 0.3,
        linewidth = 0.8,
        fill = "blue",
        color = "blue"
      ) +
      ggplot2::labs(
        title = param_name,
        x = "Median Value",
        y = "Density"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(hjust = 0.5),
        panel.grid.major = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank(),
        axis.line = ggplot2::element_line(color = "black"),
        axis.ticks = ggplot2::element_line(color = "black")
      )

    plot_list[[j]] <- p
  }

  # Render pages
  for (page in 1:n_pages) {
    start_idx <- (page - 1) * plots_per_page + 1
    end_idx <- min(page * plots_per_page, n_params)

    page_plots <- plot_list[start_idx:end_idx]

    # Arrange plots for this page
    gridExtra::grid.arrange(
      grobs = page_plots,
      ncol = n_cols,
      nrow = n_rows
    )

    # Interactive mode
    if (interactive && page < n_pages) {
      readline(prompt = "Press [Enter] to continue to the next page...")
    }
  }

  invisible(NULL)
}

#' Plot resample forest plots
#'
#' Create forest plots showing parameter ranges across resample iterations.
#' Each iteration is displayed as a horizontal line with quantile intervals.
#'
#' @param data List of abc results from abc_resample
#' @param n_rows Number of rows in plot grid (default 2)
#' @param n_cols Number of columns in plot grid (default 2)
#' @param interactive Whether to pause between pages (default FALSE)
#' @param ci_level quantile intervals (default 0.95 for 95\% interval)
#'
#' @examples
#' \dontrun{
#' # Load ABC input data from example simulation
#' abc_input <- readRDS(
#'   system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
#' )
#'
#' # Perform ABC resampling
#' results <- abc_resample(
#'   target = abc_input$target,
#'   param = abc_input$param,
#'   sumstat = abc_input$sumstat,
#'   n_iterations = 100,
#'   n_samples = 100,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#'
#' # plot forest plots showing parameter ranges
#' plot_resample_forest(results, ci_level = 0.95)
#' }
#' @export
plot_resample_forest <- function(
    data,
    n_rows = 2,
    n_cols = 2,
    interactive = FALSE,
    ci_level = 0.95) {
  # Validate input: should be a list of abc results
  if (!is.list(data) || length(data) == 0) {
    stop("data must be a non-empty list of abc results from abc_resample")
  }

  # Validate ci_level
  if (ci_level <= 0 || ci_level >= 1) {
    stop("ci_level must be between 0 and 1")
  }

  # Calculate quantile probabilities
  alpha <- 1 - ci_level
  lower_prob <- alpha / 2
  upper_prob <- 1 - alpha / 2

  n_iterations <- length(data)

  # Get first iteration to determine structure
  first_model <- data[[1]]
  param_matrix <- extract_abc_param_values(first_model)
  n_params <- ncol(param_matrix)
  param_names <- colnames(param_matrix)
  if (is.null(param_names)) {
    param_names <- paste0("param_", 1:n_params)
  }

  plots_per_page <- n_rows * n_cols
  n_pages <- ceiling(n_params / plots_per_page)

  # NSE variable bindings for R CMD check
  iteration <- lower <- upper <- median <- NULL

  # Create plots for each parameter
  plot_list <- list()
  for (j in 1:n_params) {
    param_name <- param_names[j]

    # Collect quantiles from all iterations for this parameter
    forest_data <- data.frame(
      iteration = integer(0),
      lower = numeric(0),
      median = numeric(0),
      upper = numeric(0)
    )

    for (i in seq_len(n_iterations)) {
      param_vals <- extract_abc_param_values(data[[i]])
      values <- param_vals[, j]

      forest_data <- rbind(forest_data, data.frame(
        iteration = i,
        lower = quantile(values, probs = lower_prob, na.rm = TRUE),
        median = median(values, na.rm = TRUE),
        upper = quantile(values, probs = upper_prob, na.rm = TRUE)
      ))
    }

    # Create forest plot
    p <- ggplot2::ggplot(forest_data, ggplot2::aes(y = iteration)) +
      ggplot2::geom_segment(
        ggplot2::aes(x = lower, xend = upper, yend = iteration),
        linewidth = 0.8,
        color = "blue"
      ) +
      ggplot2::geom_point(
        ggplot2::aes(x = median),
        size = 2,
        color = "darkblue"
      ) +
      ggplot2::labs(
        title = param_name,
        x = "Parameter Value",
        y = "Iteration"
      ) +
      ggplot2::scale_y_reverse() +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(hjust = 0.5),
        panel.grid.major.x = ggplot2::element_line(color = "gray90"),
        panel.grid.minor = ggplot2::element_blank(),
        axis.line = ggplot2::element_line(color = "black"),
        axis.ticks = ggplot2::element_line(color = "black")
      )

    plot_list[[j]] <- p
  }

  # Render pages
  for (page in 1:n_pages) {
    start_idx <- (page - 1) * plots_per_page + 1
    end_idx <- min(page * plots_per_page, n_params)

    page_plots <- plot_list[start_idx:end_idx]

    # Arrange plots for this page
    gridExtra::grid.arrange(
      grobs = page_plots,
      ncol = n_cols,
      nrow = n_rows
    )

    # Interactive mode
    if (interactive && page < n_pages) {
      readline(prompt = "Press [Enter] to continue to the next page...")
    }
  }

  invisible(NULL)
}

#' Summarise resample medians
#'
#' Calculate summary statistics for parameter medians across resample iterations.
#' Returns mean, median, and confidence intervals of the median distributions.
#'
#' @param data List of abc results from abc_resample
#' @param ... Additional custom summary functions (named functions)
#' @param ci_level Confidence level for intervals (default 0.95)
#' @return Data frame with summary statistics for each parameter
#'
#' @examples
#' \dontrun{
#' # Load ABC input data from example simulation
#' abc_input <- readRDS(
#'   system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
#' )
#'
#' # Perform ABC resampling
#' results <- abc_resample(
#'   target = abc_input$target,
#'   param = abc_input$param,
#'   sumstat = abc_input$sumstat,
#'   n_iterations = 100,
#'   n_samples = 100,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#'
#' # summarise the resample medians
#' summary_stats <- summarise_resample_medians(results, ci_level = 0.95)
#' print(summary_stats)
#' }
#' @export
summarise_resample_medians <- function(data, ..., ci_level = 0.95) {
  # check the parameters
  dots <- rlang::list2(...)

  # Extract any custom summary functions from dots
  # Functions passed directly are treated as custom summaries
  is_fun <- vapply(dots, is.function, logical(1))
  summary_funs <- dots[is_fun]
  dots <- dots[!is_fun]

  # Extract medians from all resample iterations
  medians_matrix <- extract_resample_medians(data)
  df <- as.data.frame(medians_matrix)

  # Get parameter names
  param_names <- colnames(df)
  if (is.null(param_names)) {
    param_names <- paste0("param_", seq_len(ncol(df)))
    colnames(df) <- param_names
  }

  # Calculate summaries for each parameter
  results <- list()

  for (param in param_names) {
    values <- df[[param]]
    values <- values[is.finite(values)]

    # Create dynamic column names with quantile values
    alpha <- 1 - ci_level
    ci_lower_name <- sprintf("ci_lower_%.3f", alpha / 2)
    ci_upper_name <- sprintf("ci_upper_%.3f", 1 - alpha / 2)

    if (length(values) == 0) {
      results[[param]] <- list(
        mean = NA_real_,
        median = NA_real_
      )
      results[[param]][[ci_lower_name]] <- NA_real_
      results[[param]][[ci_upper_name]] <- NA_real_
    } else {
      # Basic summaries
      alpha <- 1 - ci_level
      ci_lower <- quantile(values, probs = alpha / 2, na.rm = TRUE)
      ci_upper <- quantile(values, probs = 1 - alpha / 2, na.rm = TRUE)

      # Create dynamic column names with quantile values
      ci_lower_name <- sprintf("ci_lower_%.3f", alpha / 2)
      ci_upper_name <- sprintf("ci_upper_%.3f", 1 - alpha / 2)

      results[[param]] <- list(
        mean = mean(values, na.rm = TRUE),
        median = median(values, na.rm = TRUE)
      )
      results[[param]][[ci_lower_name]] <- as.numeric(ci_lower)
      results[[param]][[ci_upper_name]] <- as.numeric(ci_upper)

      # Apply custom summary functions if provided
      if (length(summary_funs) > 0) {
        for (fun_name in names(summary_funs)) {
          fun <- summary_funs[[fun_name]]
          results[[param]][[fun_name]] <- fun(values)
        }
      }
    }
  }

  # Convert to data frame
  summary_df <- do.call(rbind, lapply(names(results), function(param) {
    row <- as.data.frame(results[[param]])
    row$parameter <- param
    row
  }))

  # Reorder columns to put parameter first
  col_order <- c("parameter", setdiff(names(summary_df), "parameter"))
  summary_df <- summary_df[, col_order]
  rownames(summary_df) <- NULL

  # Add attributes
  attr(summary_df, "ci_level") <- ci_level
  attr(summary_df, "n_iterations") <- nrow(df)

  return(summary_df)
}
