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
#' Posterior predictions are first summarized to their median RT within each
#' condition and facet group before plotting. This provides a representative
#' estimate from the posterior distribution rather than pooling all individual
#' trial-level predictions.
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
  cols_to_select <- unique(c("rt", "item_idx", "condition_idx", facet_x, facet_y))

  # Get simulated data from output object and summarize to posterior medians
  simulated_df <- simulated_output$open_dataset() |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::collect() |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c("condition_idx", facet_x, facet_y)))) |>
    dplyr::summarise(rt = stats::median(rt), .groups = "drop") |>
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
