#' Summarise posterior parameter distributions
#'
#' Compute summary statistics (mean, median, confidence intervals) for posterior
#' parameters from ABC results.
#'
#' @param data An object containing posterior samples. The expected structure
#'   depends on the method dispatched.
#' @param ... Additional arguments passed to class-specific methods.
#'
#' @return A data frame with summary statistics for each parameter.
#'
#' @seealso
#'   \code{\link{summarise_posterior_parameters.abc}}
#'
#' @examples
#' # Load ABC output from saved file
#' abc_file <- system.file(
#'   "extdata", "rdm_minimal", "abc", "abc_rejection_model.rds",
#'   package = "eam"
#' )
#' abc_rejection_model <- readRDS(abc_file)
#'
#' # Summarise posterior distributions
#' summarise_posterior_parameters(abc_rejection_model)
#'
#' # Custom confidence interval level
#' summarise_posterior_parameters(abc_rejection_model, ci_level = 0.90)
#'
#' @export
summarise_posterior_parameters <- function(data, ...) {
  UseMethod("summarise_posterior_parameters")
}

#' @rdname summarise_posterior_parameters
#' @method summarise_posterior_parameters abc
#'
#' @param data An \code{abc} object containing posterior samples in
#'   \code{adj.values} or \code{unadj.values}.
#' @param ci_level Numeric; confidence interval level (default: 0.95).
#' @param ... Additional arguments for custom summary functions. Functions passed
#'   as named arguments will be applied to each parameter's posterior samples.
#'
#' @export
summarise_posterior_parameters.abc <- function(data, ..., ci_level = 0.95) {
  # check the parameters
  dots <- rlang::list2(...)

  # Extract any custom summary functions from dots
  # Functions passed directly are treated as custom summaries
  is_fun <- vapply(dots, is.function, logical(1))
  summary_funs <- dots[is_fun]
  dots <- dots[!is_fun]

  # Extract values - prefer adjusted over unadjusted
  if (!is.null(data$adj.values)) {
    df <- as.data.frame(data$adj.values)
  } else if (!is.null(data$unadj.values)) {
    df <- as.data.frame(data$unadj.values)
  } else {
    stop("Neither `adj.values` nor `unadj.values` found in the abc object.")
  }

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
      ci_lower <- stats::quantile(values, probs = alpha / 2, na.rm = TRUE)
      ci_upper <- stats::quantile(values, probs = 1 - alpha / 2, na.rm = TRUE)

      # Create dynamic column names with quantile values
      ci_lower_name <- sprintf("ci_lower_%.3f", alpha / 2)
      ci_upper_name <- sprintf("ci_upper_%.3f", 1 - alpha / 2)

      results[[param]] <- list(
        mean = mean(values, na.rm = TRUE),
        median = stats::median(values, na.rm = TRUE)
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
  attr(summary_df, "n_samples") <- nrow(df)

  return(summary_df)
}
