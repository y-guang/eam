#' Plot RT Distributions for Posterior and Observed Data
#'
#' Creates density plots comparing reaction time distributions between
#' posterior simulations and observed data, with optional faceting.
#'
#' @param simulated_output Simulation output object with an `open_dataset()` method
#' @param observed_df Data frame containing observed data
#' @param facet_x Character vector of column names for x-axis faceting (default: "item_idx")
#' @param facet_y Character vector of column names for y-axis faceting (default: empty)
#'
#' @return A ggplot2 object showing density plots
#' @export
plot_rt <- function(
    simulated_output,
    observed_df,
    facet_x = c("item_idx"),
    facet_y = c()) {
  # Determine all columns to select
  cols_to_select <- unique(c("rt", "item_idx", facet_x, facet_y))

  # Get simulated data from output object
  simulated_df <- simulated_output$open_dataset() |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::collect() |>
    dplyr::mutate(source = "posterior")

  # Get observed data with same columns
  observed_df <- observed_df |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::mutate(source = "observed")

  # Combine both dataframes
  combined_df <- dplyr::bind_rows(simulated_df, observed_df)

  # Plot densities
  p <- combined_df |>
    ggplot2::ggplot() +
    ggplot2::geom_density(ggplot2::aes(x = rt, fill = source), alpha = 0.6) +
    ggplot2::scale_fill_manual(values = c(posterior = "blue", observed = "red"))

  # Add faceting: use facet_grid if both x and y specified, otherwise facet_wrap
  if (length(facet_y) > 0) {
    facet_formula <- stats::as.formula(paste(
      paste(facet_y, collapse = " + "),
      "~",
      paste(facet_x, collapse = " + ")
    ))
    p <- p + ggplot2::facet_grid(facet_formula)
  } else {
    facet_formula <- stats::as.formula(paste("~", paste(facet_x, collapse = " + ")))
    p <- p + ggplot2::facet_wrap(facet_formula)
  }

  p <- p +
    ggplot2::theme_minimal() +
    ggplot2::labs(fill = "Source")

  return(p)
}