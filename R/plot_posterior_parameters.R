#' Plot parameter posterior distributions
#'
#' Plotting posterior distributions (and optionally prior distributions) from ABC results.
#'
#' @param data An object containing posterior samples. The expected structure
#'   depends on the method dispatched.
#' @param ... Additional arguments passed to class-specific methods.
#'
#' @return Invisibly returns `NULL`. Called for its side effect of producing plots.
#'
#' @seealso
#'   \code{\link{plot_posterior_parameters.abc}}
#'
#' @examples
#' # Load ABC output from saved file
#' abc_file <- system.file(
#'   "extdata", "rdm_minimal", "abc", "abc_rejection_model.rds",
#'   package = "eam"
#' )
#' abc_rejection_model <- readRDS(abc_file)
#'
#' # Load ABC input for prior comparison
#' abc_input_file <- system.file(
#'   "extdata", "rdm_minimal", "abc", "abc_input.rds",
#'   package = "eam"
#' )
#' abc_input <- readRDS(abc_input_file)
#'
#' # Plot posterior distributions with prior comparison
#' plot_posterior_parameters(abc_rejection_model, abc_input)
#'
#' @export
plot_posterior_parameters <- function(data, ...) {
  UseMethod("plot_posterior_parameters")
}

#' @rdname plot_posterior_parameters
#' @method plot_posterior_parameters abc
#'
#' @param data An \code{abc} object containing posterior samples in
#'   \code{adj.values} or \code{unadj.values}.
#' @param abc_input Optional abc_input object containing prior samples for comparison.
#'   If provided, prior distributions are shown as red histograms and posterior
#'   distributions as blue density curves.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{n_rows}{Integer; number of rows in the plot grid (default: 2)}
#'     \item{n_cols}{Integer; number of columns in the plot grid (default: 2)}
#'     \item{interactive}{Logical; whether to pause between pages and wait for input}
#'   }
#'
#' @details
#' The plots use the following visual encoding:
#' \itemize{
#'   \item Posterior distributions: blue density curves
#'   \item Prior distributions (if provided): red histograms with transparency
#' }
#'
#' @export
plot_posterior_parameters.abc <- function(data, abc_input = NULL, ...) {
  # Get posterior samples - prefer adj.values, fallback to unadj.values
  posterior <- NULL
  if (!is.null(data$adj.values)) {
    posterior <- data$adj.values
  } else if (!is.null(data$unadj.values)) {
    posterior <- data$unadj.values
  } else {
    stop("data must contain either adj.values or unadj.values")
  }

  # Convert to data frame if needed
  if (!is.data.frame(posterior)) {
    posterior <- as.data.frame(posterior)
  }

  # Get parameter names
  n_params <- ncol(posterior)
  param_names <- colnames(posterior)
  if (is.null(param_names)) {
    param_names <- paste0("param_", 1:n_params)
  }

  # Get prior samples if abc_input is provided
  prior <- NULL
  if (!is.null(abc_input)) {
    if (!is.null(abc_input$param)) {
      prior <- abc_input$param
      if (!is.data.frame(prior)) {
        prior <- as.data.frame(prior)
      }
      # Ensure prior has the same parameter names
      if (ncol(prior) != n_params) {
        warning("prior has different number of parameters than posterior. Ignoring prior.")
        prior <- NULL
      } else {
        colnames(prior) <- param_names
      }
    }
  }

  # Check parameters
  dots <- rlang::list2(...)
  n_rows <- dots$n_rows %||% 2
  dots$n_rows <- rlang::zap()
  n_cols <- dots$n_cols %||% 2
  dots$n_cols <- rlang::zap()
  interactive <- dots$interactive %||% FALSE
  dots$interactive <- rlang::zap()

  plots_per_page <- n_rows * n_cols
  n_pages <- ceiling(n_params / plots_per_page)

  # NSE variable bindings for R CMD check
  value <- type <- NULL

  # Create plots for each parameter
  plot_list <- list()
  for (j in 1:n_params) {
    param_name <- param_names[j]

    # Prepare data for plotting
    plot_df <- data.frame(
      value = posterior[, j],
      type = "Posterior"
    )

    # Add prior data if available
    if (!is.null(prior)) {
      prior_df <- data.frame(
        value = prior[, j],
        type = "Prior"
      )
      plot_df <- rbind(plot_df, prior_df)
    }

    # Create plot with histogram for Prior and density for Posterior
    p <- ggplot2::ggplot() +
      ggplot2::labs(
        title = param_name,
        x = "Value",
        y = "Density"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        panel.grid.major = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank(),
        axis.line = ggplot2::element_line(color = "black"),
        axis.ticks = ggplot2::element_line(color = "black"),
        legend.position = "none"
      )

    # Add Prior as histogram if available
    if (!is.null(prior)) {
      p <- p +
        ggplot2::geom_histogram(
          data = dplyr::filter(plot_df, type == "Prior"),
          ggplot2::aes(x = value, y = ggplot2::after_stat(density), fill = type),
          bins = 30,
          alpha = 0.3,
          color = "red"
        )
    }

    # Add Posterior as density curve
    p <- p +
      ggplot2::geom_density(
        data = dplyr::filter(plot_df, type == "Posterior"),
        ggplot2::aes(x = value, color = type),
        linewidth = 0.9
      ) +
      ggplot2::scale_color_manual(
        values = c("Posterior" = "blue", "Prior" = "red")
      ) +
      ggplot2::scale_fill_manual(
        values = c("Posterior" = "blue", "Prior" = "red")
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
