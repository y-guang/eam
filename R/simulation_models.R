#' Run a single trial of the DDM simulation
#'
#' This function runs a single trial of the DDM simulation using the provided
#' item formulas and trial settings. It's a wrapper around the core C++ function
#' @param trial_setting A list of named values representing the trial settings
#' @param item_formulas A list of formulas defining the item parameters
#' @param n_items The number of items to simulate
#' @param max_reached The threshold for evidence accumulation
#' @param max_t The maximum time to simulate
#' @param dt The step size for each increment
#' @param noise_mechanism The noise mechanism to use ("add" or "mult")
#' @param noise_factory A function that takes trial_setting and returns a noise
#' function with signature function(n, dt)
#' @param trajectories Whether to return full output including trajectories.
#' @return A list containing the simulation results
#' @note After evaluation, parameters A, V, and ndt are expected to be
#' numeric vectors of length n_items. And they are matched by position. So,
#' the first element of A, V, and ndt corresponds to the first item, and so on.
#' @keywords internal
run_trial_ddm <- function(
    trial_setting,
    item_formulas,
    n_items,
    max_reached,
    max_t,
    dt,
    noise_mechanism,
    noise_factory,
    trajectories = FALSE) {
  # prepare
  item_params <- evaluate_with_dt(
    item_formulas,
    data = trial_setting,
    n = n_items
  )
  noise_fun <- noise_factory(trial_setting)

  # default Z to 0 if not provided
  Z <- if (is.null(item_params$Z)) rep(0, n_items) else item_params$Z

  sim_result <- accumulate_evidence_ddm(
    item_params$A,
    item_params$V,
    Z,
    item_params$ndt,
    max_t,
    dt,
    max_reached,
    noise_mechanism,
    noise_fun
  )

  if (trajectories) {
    sim_result$.item_params <- item_params
  }

  sim_result
}


#' Run a single trial of the 2-boundary DDM simulation
#'
#' This function runs a single trial of the 2-boundary DDM simulation using the
#' provided item formulas and trial settings. It's a wrapper around the core C++
#' function for 2-boundary DDM.
#' @param trial_setting A list of named values representing the trial settings
#' @param item_formulas A list of formulas defining the item parameters
#' @param n_items The number of items to simulate
#' @param max_reached The threshold for evidence accumulation
#' @param max_t The maximum time to simulate
#' @param dt The step size for each increment
#' @param noise_mechanism The noise mechanism to use ("add", "mult_evidence",
#' or "mult_t")
#' @param noise_factory A function that takes trial_setting and returns a noise
#' function with signature function(n, dt)
#' @param trajectories Whether to return full output including trajectories.
#' @return A list containing the simulation results
#' @note After evaluation, parameters A_upper, A_lower, V, and ndt are expected
#' to be numeric vectors of length n_items. And they are matched by position.
#' So, the first element of A_upper, A_lower, V, and ndt corresponds to the
#' first item, and so on.
#' @keywords internal
run_trial_ddm_2b <- function(
    trial_setting,
    item_formulas,
    n_items,
    max_reached,
    max_t,
    dt,
    noise_mechanism,
    noise_factory,
    trajectories = FALSE) {
  # prepare
  item_params <- evaluate_with_dt(
    item_formulas,
    data = trial_setting,
    n = n_items
  )
  noise_fun <- noise_factory(trial_setting)

  # default Z to 0 if not provided
  Z <- if (is.null(item_params$Z)) rep(0, n_items) else item_params$Z

  sim_result <- accumulate_evidence_ddm_2b(
    item_params$A_upper,
    item_params$A_lower,
    item_params$V,
    Z,
    item_params$ndt,
    max_t,
    dt,
    max_reached,
    noise_mechanism,
    noise_fun
  )

  if (trajectories) {
    sim_result$.item_params <- item_params
  }

  sim_result
}


#' Run a single trial of the LCA-GI simulation
#'
#' This function runs a single trial of the LCA-GI (Leaky Competing Accumulator
#' with Global Inhibition) simulation using the provided item formulas and trial
#' settings. It's a wrapper around the core C++ function for LCA-GI.
#' @param trial_setting A list of named values representing the trial settings
#' @param item_formulas A list of formulas defining the item parameters
#' @param n_items The number of items to simulate
#' @param max_reached The threshold for evidence accumulation
#' @param max_t The maximum time to simulate
#' @param dt The step size for each increment
#' @param noise_factory A function that takes trial_setting and returns a noise
#' function with signature function(n, dt)
#' @param trajectories Whether to return full output including trajectories.
#' @return A list containing the simulation results
#' @note After evaluation, parameters A, V, ndt, beta, and k are expected
#' to be numeric vectors of length n_items. And they are matched by position.
#' So, the first element of A, V, ndt, beta, and k corresponds to the first
#' item, and so on.
#' @keywords internal
run_trial_lca_gi <- function(
    trial_setting,
    item_formulas,
    n_items,
    max_reached,
    max_t,
    dt,
    noise_factory,
    trajectories = FALSE) {
  # prepare
  item_params <- evaluate_with_dt(
    item_formulas,
    data = trial_setting,
    n = n_items
  )
  noise_fun <- noise_factory(trial_setting)

  # default Z to 0 if not provided
  Z <- if (is.null(item_params$Z)) rep(0, n_items) else item_params$Z

  sim_result <- accumulate_evidence_lca_gi(
    item_params$A,
    item_params$V,
    Z,
    item_params$ndt,
    item_params$beta,
    item_params$k,
    max_t,
    dt,
    max_reached,
    noise_fun
  )

  if (trajectories) {
    sim_result$.item_params <- item_params
  }

  sim_result
}