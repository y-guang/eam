#' Plot reaction time distributions
#'
#' Visualize reaction time distributions from your model predictions.
#' Overlay observed experimental data for reference.
#'
#' @param simulated_output Output from \code{\link{run_simulation}} containing
#'   posterior predictions
#' @param observed_df Your observed data as a data frame
#' @param facet_x Variables to split plots horizontally. Default is \code{"item_idx"}
#'   to show separate plots for each item
#' @param facet_y Variables to split plots vertically. Default is none (\code{c()})
#'
#' @details
#' Posterior predictions are plotted directly at the trial level. This pools
#' all simulated trials for the requested facets without condition-level
#' aggregation.
#'
#' @return A plot showing predicted RT distributions (blue), with observed data (red) if provided
#'
#' @examples
#' # Load example posterior simulation output
#' post_output_path <- system.file(
#'   "extdata", "rdm_minimal", "abc", "posterior", "neuralnet",
#'   package = "eam"
#' )
#' post_output <- load_simulation_output(post_output_path)
#'
#' # Load example observed data
#' obs_file <- system.file(
#'   "extdata", "rdm_minimal", "observation", "observation_data.csv",
#'   package = "eam"
#' )
#' obs_df <- read.csv(obs_file)
#'
#' # Plot RT distributions by item
#' plot_rt(post_output, obs_df, facet_x = c("item_idx"))
#'
#' # Plot RT distributions by item and group
#' plot_rt(
#'   post_output,
#'   obs_df,
#'   facet_x = c("item_idx"),
#'   facet_y = c("group")
#' )
#'
#' @export
plot_rt <- function(
    simulated_output,
    observed_df,
    facet_x = c("item_idx"),
    facet_y = c()) {
  # NSE variable bindings for R CMD check
  rt <- source <- NULL

  # Determine all columns to select
  cols_to_select <- unique(c("rt", facet_x, facet_y))

  # Get simulated data from output object at trial level
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

  combined_df <- combined_df |>
    dplyr::mutate(source = factor(source, levels = c("posterior", "observed"), labels = c("Simulation", "Observed")))

  # Plot densities for simulated and histogram for observed
  p <- combined_df |>
    ggplot2::ggplot(ggplot2::aes(x = rt, color = source, fill = source)) +
    ggplot2::geom_density(
      data = dplyr::filter(combined_df, source == "Simulation"),
      alpha = 0.25,
      linewidth = 1
    ) +
    ggplot2::geom_histogram(
      data = dplyr::filter(combined_df, source == "Observed"),
      ggplot2::aes(y = ggplot2::after_stat(density)),
      alpha = 0.25,
      bins = 30,
      position = "identity"
    ) +
    ggplot2::scale_fill_manual(values = c(Simulation = "steelblue", Observed = "red")) +
    ggplot2::scale_color_manual(values = c(Simulation = "steelblue", Observed = "red"))

  # Add faceting while preserving separate handling for column and row splits.
  if (length(facet_y) > 0 && length(facet_x) > 0) {
    facet_formula <- stats::as.formula(paste(
      paste(facet_y, collapse = " + "),
      "~",
      paste(facet_x, collapse = " + ")
    ))
    p <- p + ggplot2::facet_grid(facet_formula, scales = "free_y")
  } else if (length(facet_x) > 0) {
    facet_formula <- stats::as.formula(paste("~", paste(facet_x, collapse = " + ")))
    p <- p + ggplot2::facet_wrap(facet_formula, scales = "free_y")
  } else if (length(facet_y) > 0) {
    facet_formula <- stats::as.formula(paste(paste(facet_y, collapse = " + "), "~ ."))
    p <- p + ggplot2::facet_grid(facet_formula, scales = "free_y")
  }

  p <- p +
    ggplot2::theme_bw() +
    ggplot2::labs(
      x = "Reaction Time",
      y = "Density",
      color = "Data",
      fill = "Data",
      title = "RT Density: Simulation vs Observed"
    )

  return(p)
}
