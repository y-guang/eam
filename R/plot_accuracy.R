#' Plot accuracy comparison
#'
#' Routes to backend-specific accuracy plotting functions based on the simulation backend.
#'
#' @param simulated_output Simulation output object with backend information
#' @param observed_df Observed data frame
#' @param x Variable for x-axis (default: "item_idx")
#' @param facet_x Variables for faceting columns
#' @param facet_y Variables for faceting rows
#' @return A ggplot2 object
#' @export
plot_accuracy <- function(
    simulated_output,
    observed_df,
    x = "item_idx",
    facet_x = c(),
    facet_y = c()) {
  backend <- simulated_output$simulation_config$backend

  switch(backend,
    "ddm-2b" = plot_accuracy_ddm_2b(simulated_output, observed_df, x, facet_x, facet_y),
    stop("Backend '", backend, "' not implemented for plot_accuracy")
  )
}

#' Plot accuracy graph (internal)
#'
#' @param accuracy_df Data frame with accuracy values
#' @param x Variable for x-axis
#' @param facet_x Variables for faceting columns
#' @param facet_y Variables for faceting rows
#' @return A ggplot2 object
#' @keywords internal
plot_accuracy_graph <- function(
    accuracy_df,
    x = "item_idx",
    facet_x = c(),
    facet_y = c()) {
  # Convert x variable to factor for discrete positioning
  accuracy_df[[x]] <- factor(accuracy_df[[x]])

  # Create bar plot with x on x-axis and source as fill, grouped by source
  p <- accuracy_df |>
    ggplot2::ggplot() +
    ggplot2::geom_bar(
      ggplot2::aes_string(x = x, y = "accuracy", fill = "source"),
      stat = "identity",
      position = "dodge"
    ) +
    ggplot2::scale_fill_manual(values = c(posterior = "blue", observed = "red")) +
    ggplot2::scale_y_continuous(limits = c(0, 1), labels = scales::percent)

  # Add faceting if facet_x or facet_y are specified
  if (length(facet_y) > 0 && length(facet_x) > 0) {
    facet_formula <- stats::as.formula(paste(
      paste(facet_y, collapse = " + "),
      "~",
      paste(facet_x, collapse = " + ")
    ))
    p <- p + ggplot2::facet_grid(facet_formula)
  } else if (length(facet_x) > 0) {
    facet_formula <- stats::as.formula(paste("~", paste(facet_x, collapse = " + ")))
    p <- p + ggplot2::facet_wrap(facet_formula)
  } else if (length(facet_y) > 0) {
    facet_formula <- stats::as.formula(paste(paste(facet_y, collapse = " + "), "~ ."))
    p <- p + ggplot2::facet_grid(facet_formula)
  }

  p <- p +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = x,
      y = "Accuracy",
      fill = "Source"
    )

  return(p)
}

#' Plot accuracy for DDM-2B model (internal)
#'
#' @param simulated_output Simulation output object
#' @param observed_df Observed data frame
#' @param x Variable for x-axis
#' @param facet_x Variables for faceting columns
#' @param facet_y Variables for faceting rows
#' @return A ggplot2 object
#' @keywords internal
plot_accuracy_ddm_2b <- function(
    simulated_output,
    observed_df,
    x = "item_idx",
    facet_x = c(),
    facet_y = c()) {
  # Avoid NSE warnings
  choice <- correct <- NULL

  # Determine all columns to select
  cols_to_select <- unique(c("choice", "item_idx", x, facet_x, facet_y))

  # Get simulated data from output object
  simulated_df <- simulated_output$open_dataset() |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::collect() |>
    dplyr::mutate(
      source = "posterior",
      correct = choice == 1 # upper bound hit
    )

  # Get observed data with same columns
  observed_df <- observed_df |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::mutate(
      source = "observed",
      correct = choice == 1 # upper bound hit
    )

  # Combine both dataframes
  combined_df <- dplyr::bind_rows(simulated_df, observed_df)

  # Calculate accuracy by grouping variables
  grouping_vars <- unique(c(x, facet_x, facet_y, "source"))

  accuracy_df <- combined_df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_vars))) |>
    dplyr::summarise(
      accuracy = mean(correct, na.rm = TRUE),
      .groups = "drop"
    )

  plot_accuracy_graph(accuracy_df, x, facet_x, facet_y)
}
