#' Build input for Amortized Bayesian Inference (ABI)
#'
#' Prepares simulation output for Amortized Bayesian Inference (ABI) analysis
#' using the \code{NeuralEstimators} package. Extracts parameters and summary statistics
#' from simulation results, splits data into training and validation sets, and formats
#' them into matrices suitable for neural network training.
#'
#' @details
#' This function provides a streamlined workflow for preparing ABI inputs. It
#' requires that \code{simulation_output} be created by \code{\link{run_simulation}}
#' or \code{\link{load_simulation_output}}. The function automatically handles
#' missing trials and ranks by filling with zeros to ensure complete data matrices.
#'
#' The output format is optimized for the \code{abi} package's training functions,
#' with parameters formatted as matrices (each column is a condition) and summary
#' statistics formatted as lists of matrices (one per condition, with trials as columns).
#'
#' @param simulation_output A eam_simulation_output object from
#'   \code{\link{run_simulation}} or \code{\link{load_simulation_output}}.
#' @param theta Character vector of parameter names to extract from simulation_output.
#'   These parameters will be used as the target variables for inference.
#' @param Z Character vector of summary statistic column names to extract from
#'   the simulation output dataset (e.g., "rt", "item_idx", "choice").
#' @param train_ratio Numeric value between 0 and 1 specifying the proportion
#'   of conditions to use for training (default: 0.8).
#' @param rank_levels Numeric vector specifying which rank indices to include.
#'   If NULL (default), uses all ranks from 1 to n_items from simulation config.
#'
#' @return A list with components suitable for \code{abi} package training:
#' \describe{
#'   \item{theta_train}{Matrix of training parameters (parameters × conditions)}
#'   \item{theta_val}{Matrix of validation parameters (parameters × conditions)}
#'   \item{Z_train}{List of matrices, one per training condition (ranks*Z × trials)}
#'   \item{Z_val}{List of matrices, one per validation condition (ranks*Z × trials)}
#'   \item{train_idx}{Vector of condition indices used for training}
#'   \item{val_idx}{Vector of condition indices used for validation}
#'   \item{train_ratio}{The training ratio used}
#'   \item{rank_levels}{The rank levels included in Z matrices}
#' }
#'
#' @examples
#' # Load the example dataset
#' rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
#' sim_output <- load_simulation_output(file.path(rdm_minimal_example, "simulation"))
#'
#' # build the ABI input
#' abi_input <- build_abi_input(
#'   sim_output,
#'   c(
#'     "V_beta_1",
#'     "V_beta_group"
#'   ),
#'   c(
#'     "item_idx",
#'     "rt",
#'     "choice"
#'   )
#' )
#'
#' # view the structure of the ABI input
#' str(abi_input)
#'
#' \dontrun{
#' # Example of using the ABI input for training
#' # (requires NeuralEstimators package and build your estimator first, see our tutorials)
#' train(
#'   estimator,
#'   theta_train = abi_input$theta_train,
#'   theta_val = abi_input$theta_val,
#'   Z_train = abi_input$Z_train,
#'   Z_val = abi_input$Z_val,
#'   epochs = 500,
#'   stopping_epochs = 200
#' )
#' }
#' @export
build_abi_input <- function(
    simulation_output,
    theta,
    Z,
    train_ratio = 0.8,
    rank_levels = NULL) {
  # Validate inputs
  if (!inherits(simulation_output, "eam_simulation_output")) {
    stop("simulation_output must be a eam_simulation_output object")
  }

  if (!is.character(theta) || length(theta) == 0) {
    stop("theta must be a non-empty character vector")
  }

  if (!is.character(Z) || length(Z) == 0) {
    stop("Z must be a non-empty character vector")
  }

  if (!is.numeric(train_ratio) || length(train_ratio) != 1) {
    stop("train_ratio must be a single numeric value")
  }

  if (train_ratio <= 0 || train_ratio >= 1) {
    stop("train_ratio must be between 0 and 1")
  }

  if (!is.null(rank_levels) && !is.numeric(rank_levels)) {
    stop("rank_levels must be NULL or a numeric vector")
  }

  # Open the arrow datasets
  output <- simulation_output$open_dataset()
  conditions <- simulation_output$open_evaluated_conditions()

  # Set default rank_levels if NULL
  if (is.null(rank_levels)) {
    max_rank <- simulation_output$simulation_config$n_items
    rank_levels <- seq_len(max_rank)
  } else if (!is.numeric(rank_levels)) {
    stop("rank_levels must be a numeric vector")
  } else {
    rank_levels <- sort(unique(rank_levels))
  }

  # collect unique condition_idx
  # NSE variable bindings for R CMD check
  condition_idx <- conditions |>
    dplyr::select(condition_idx) |>
    dplyr::distinct() |>
    dplyr::arrange(condition_idx) |>
    dplyr::collect() |>
    dplyr::pull(condition_idx)

  # Split into train and validation sets
  n_total <- length(condition_idx)
  n_train <- floor(n_total * train_ratio)
  train_idx <- sample(condition_idx, n_train, replace = FALSE)
  val_idx <- setdiff(condition_idx, train_idx)

  # build theta matrices
  theta_train <- build_abi_input.theta(
    conditions,
    theta,
    train_idx
  )
  theta_val <- build_abi_input.theta(
    conditions,
    theta,
    val_idx
  )
  z_train <- build_abi_input.Z(
    output,
    Z,
    rank_levels,
    train_idx,
    simulation_output$simulation_config$n_trials_per_condition
  )

  z_val <- build_abi_input.Z(
    output,
    Z,
    rank_levels,
    val_idx,
    simulation_output$simulation_config$n_trials_per_condition
  )

  # build output list
  abi_input <- list(
    theta_train = theta_train,
    theta_val = theta_val,
    Z_train = z_train,
    Z_val = z_val,
    train_idx = train_idx,
    val_idx = val_idx,
    train_ratio = train_ratio,
    rank_levels = rank_levels
  )

  return(abi_input)
}

#' Extract and format parameter matrix for ABI
#'
#' @param conditions Arrow dataset of evaluated conditions
#' @param theta Character vector of parameter names
#' @param select_idx Vector of condition indices to extract
#' @return Matrix with parameters as rows and conditions as columns
#' @keywords internal
build_abi_input.theta <- function(
    conditions,
    theta,
    select_idx) {
  # NSE variable bindings for R CMD check
  condition_idx <- NULL

  # Filter by train_idx and select theta columns
  theta_df <- conditions |>
    dplyr::filter(condition_idx %in% select_idx) |>
    dplyr::select(condition_idx, dplyr::all_of(theta)) |>
    dplyr::arrange(condition_idx) |>
    dplyr::collect()

  # Convert to matrix (excluding condition_idx column)
  # Each column is a trial (Fortran style)
  theta_matrix <- as.matrix(theta_df[, theta, drop = FALSE])
  theta_matrix <- t(theta_matrix)

  return(theta_matrix)
}

#' Extract and format summary statistics for ABI
#'
#' @param output Arrow dataset of simulation output
#' @param Z Character vector of summary statistic column names
#' @param rank_levels Numeric vector of rank indices to include
#' @param select_idx Vector of condition indices to extract
#' @param n_trials_per_condition Number of trials per condition
#' @return List of matrices, one per condition (ranks*Z rows × trials columns)
#' @keywords internal
build_abi_input.Z <- function(
    output,
    Z,
    rank_levels,
    select_idx,
    n_trials_per_condition) {
  # NSE variable bindings for R CMD check
  condition_idx <- trial_idx <- rank_idx <- NULL

  fill_list <- rlang::set_names(
    as.list(rep(0, length(Z))),
    Z
  )

  # Generate all trial indices
  all_trial_idx <- seq_len(n_trials_per_condition)

  # Filter by select_idx and rank_levels, then select Z columns
  z_complete <- output |>
    dplyr::filter(condition_idx %in% select_idx, rank_idx %in% rank_levels) |>
    dplyr::select(condition_idx, trial_idx, rank_idx, dplyr::all_of(Z)) |>
    dplyr::collect() |>
    tidyr::complete(
      condition_idx = select_idx,
      trial_idx = all_trial_idx,
      rank_idx = rank_levels,
      fill = fill_list
    ) |>
    dplyr::arrange(condition_idx, trial_idx, rank_idx) |>
    tidyr::pivot_wider(
      names_from = rank_idx,
      values_from = dplyr::all_of(Z),
      names_glue = "rank_{rank_idx}_{.value}"
    )

  # Convert to list of matrices, one per condition
  # Each matrix has trials as columns and (rank * Z) as rows
  z_list <- z_complete |>
    dplyr::select(-trial_idx) |>
    dplyr::group_by(condition_idx) |>
    dplyr::group_split(.keep = FALSE) |>
    purrr::map(function(cond_df) {
      cond_df |>
        as.matrix() |>
        t()
    })

  return(z_list)
}
