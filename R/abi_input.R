# trnaslate data to abi-api friendly
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

# @keyword internal
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

# @keyword internal
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
    dplyr::group_by(condition_idx) |>
    dplyr::group_split() |>
    purrr::map(function(cond_df) {
      cond_df |>
        dplyr::select(-condition_idx, -trial_idx) |>
        as.matrix() |>
        t()
    })

  return(z_list)
}



test_result <- build_abi_input(
  sim_output,
  c(
    "A_beta_0",
    "A_beta_1",
    "V_beta_0",
    "V_beta_1"
  ), c(
    "item_idx",
    "rt"
  ),
  rank_levels = c(
    1, 2, 3
  )
)
