#' Extract all left-hand side variable names from config formulas and prior_params
#'
#' @param config A list containing simulation configuration parameters
#' @return A character vector of all LHS variable names from formulas and prior_params columns
#' @keywords internal
get_config_env_names <- function(config) {
  # Extract LHS names from item_formulas (list of formulas)
  item_names <- sapply(config$item_formulas, function(f) {
    rlang::as_name(rlang::f_lhs(f))
  })

  # Extract LHS names from between_trial_formulas (list of formulas)
  between_trial_names <- sapply(config$between_trial_formulas, function(f) {
    rlang::as_name(rlang::f_lhs(f))
  })

  # Extract LHS names from prior_formulas (list of formulas)
  prior_names <- sapply(config$prior_formulas, function(f) {
    rlang::as_name(rlang::f_lhs(f))
  })

  # Extract column names from prior_params (data frame) if it exists
  prior_params_names <- if (!is.null(config$prior_params)) {
    names(config$prior_params)
  } else {
    character(0)
  }

  # Combine all names
  all_names <- c(item_names, between_trial_names, prior_names, prior_params_names)

  return(all_names)
}

#' Backend detector for standard DDM
#'
#' @param model_lower Lowercase model name
#' @param config A list containing simulation configuration parameters
#' @return Backend name if this detector handles the config, NULL otherwise
#' @keywords internal
detect_backend_ddm <- function(model_lower, config) {
  lhs_names <- get_config_env_names(config)

  switch(model_lower,
    "ddm-1b" = "ddm",
    "ddm" = {
      if ("A" %in% lhs_names) "ddm" else NULL
    },
    NULL
  )
}

#' Backend detector for 2-boundary DDM
#'
#' @param model_lower Lowercase model name
#' @param config A list containing simulation configuration parameters
#' @return Backend name if this detector handles the config, NULL otherwise
#' @keywords internal
detect_backend_ddm_2b <- function(model_lower, config) {
  lhs_names <- get_config_env_names(config)

  switch(model_lower,
    "ddm-2b" = "ddm-2b",
    "rdm" = "ddm-2b",
    "ddm" = {
      if ("A_upper" %in% lhs_names) "ddm-2b" else NULL
    },
    NULL
  )
}

#' Backend detector for LCA-GI
#'
#' @param model_lower Lowercase model name
#' @param config A list containing simulation configuration parameters
#' @return Backend name if this detector handles the config, NULL otherwise
#' @keywords internal
detect_backend_lca_gi <- function(model_lower, config) {
  switch(model_lower,
    "lca" = "lca-gi",
    "lca-gi" = "lca-gi",
    NULL
  )
}

#' Get all registered backend detectors
#'
#' @return A list of backend detector functions
#' @keywords internal
get_backend_detectors <- function() {
  list(
    detect_backend_ddm_2b, # Check 2-boundary first (more specific)
    detect_backend_ddm,
    detect_backend_lca_gi
  )
}

#' Route model alias to backend and enrich configuration
#'
#' This function uses a registry of backend detectors to determine which
#' backend implementation should handle the given configuration. Each detector
#' examines the config and returns a backend name if it can handle it, or NULL
#' otherwise. This design pattern (Chain of Responsibility) makes it easy to
#' add new backends without modifying this routing function.
#'
#' @param config A list containing simulation configuration parameters
#' @return The modified config list with added 'backend' parameter
#' @keywords internal
route_model_to_backend <- function(config) {
  model_lower <- tolower(config$model)
  detectors <- get_backend_detectors()

  # Apply all detectors and collect non-NULL results
  detected_backends <- lapply(detectors, function(detector) {
    detector(model_lower, config)
  })

  # Filter out NULL results
  detected_backends <- Filter(Negate(is.null), detected_backends)

  # Check for errors
  if (length(detected_backends) == 0) {
    stop(
      "According to the configuration, no backend was found for model '",
      config$model,
      "'. Please check your configuration."
    )
  }

  if (length(detected_backends) > 1) {
    stop(
      "According to the configuration, multiple backends were found for model '",
      config$model, "': ",
      paste0("'", detected_backends, "'", collapse = ", "),
      ". Please check your configuration to resolve the ambiguity. ",
      "Or potentially, directly specify the backend name as model name, to bypass",
      " the automatic detection mechanism."
    )
  }

  # Add backend to config
  config$backend <- detected_backends[[1]]

  return(config)
}
