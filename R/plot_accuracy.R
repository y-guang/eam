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
    "ddm" = plot_accuracy_ddm(simulated_output, observed_df, x, facet_x, facet_y),
    stop("Backend '", backend, "' not implemented for plot_accuracy")
  )
}

#' Plot accuracy graph (internal)
#'
#' @param accuracy_df Data frame with accuracy values
#' @param x Variable for x-axis
#' @param y Variable for y-axis (default: "accuracy")
#' @param facet_x Variables for faceting columns
#' @param facet_y Variables for faceting rows
#' @return A ggplot2 object
#' @keywords internal
plot_accuracy_graph <- function(
    accuracy_df,
    x = "item_idx",
    y = "accuracy",
    facet_x = c(),
    facet_y = c()) {
  # Convert x variable to factor for discrete positioning
  accuracy_df[[x]] <- factor(accuracy_df[[x]])

  # Create bar plot with x on x-axis and source as fill, grouped by source
  p <- accuracy_df |>
    ggplot2::ggplot() +
    ggplot2::geom_bar(
      ggplot2::aes_string(x = x, y = y, fill = "source"),
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
      y = stringr::str_to_title(gsub("_", " ", y)),
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

  plot_accuracy_graph(accuracy_df, x, "accuracy", facet_x, facet_y)
}

#' Plot accuracy for DDM model (internal)
#'
#' Calculates hit rate (proportion of trials with choice == 1) across all possible
#' trial combinations. For simulated data, expands grid based on simulation config
#' parameters and left joins with actual simulation results. For observed data,
#' assumes data is already in the correct format.
#'
#' @param simulated_output Simulation output object
#' @param observed_df Observed data frame (already expanded with all trial combinations)
#' @param x Variable for x-axis
#' @param facet_x Variables for faceting columns
#' @param facet_y Variables for faceting rows
#' @return A ggplot2 object
#' @keywords internal
plot_accuracy_ddm <- function(
    simulated_output,
    observed_df,
    x = "item_idx",
    facet_x = c(),
    facet_y = c()) {
  # Avoid NSE warnings
  hit <- rt <- NULL

  # Get simulation configuration parameters
  config <- simulated_output$simulation_config
  n_conditions <- config$n_conditions
  n_trials_per_condition <- config$n_trials_per_condition
  n_items <- config$n_items

  # Determine all columns to select (DDM has rt column)
  cols_to_select <- unique(c("rt", "condition_idx", "trial_idx", "item_idx", x, facet_x, facet_y))

  # Create expanded grid of all possible trial combinations for simulated data
  all_trials_df <- tidyr::expand_grid(
    condition_idx = seq_len(n_conditions),
    trial_idx = seq_len(n_trials_per_condition),
    item_idx = seq_len(n_items)
  )

  # Get simulated data and left join with all possible trials
  simulated_df <- simulated_output$open_dataset() |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::collect()

  # Left join to include all possible trials
  # In DDM, presence of rt (reaction time) means hit, absence (NA) means no hit
  simulated_df <- all_trials_df |>
    dplyr::left_join(
      simulated_df,
      by = c("condition_idx", "trial_idx", "item_idx")
    ) |>
    dplyr::mutate(
      source = "posterior",
      hit = dplyr::if_else(is.na(rt), 0, 1)
    )

  # Get observed data (from true dataset)
  # In DDM, presence of rt (not NA) means hit, NA means no hit
  observed_df <- observed_df |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::mutate(
      source = "observed",
      hit = dplyr::if_else(is.na(rt), 0, 1)
    )

  # Combine both dataframes
  combined_df <- dplyr::bind_rows(simulated_df, observed_df)

  # Calculate hit rate by grouping variables
  grouping_vars <- unique(c(x, facet_x, facet_y, "source"))

  accuracy_df <- combined_df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_vars))) |>
    dplyr::summarise(
      hit_rate = mean(hit, na.rm = TRUE),
      .groups = "drop"
    )

  plot_accuracy_graph(accuracy_df, x, "hit_rate", facet_x, facet_y)
}
