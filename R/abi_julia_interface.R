# Package environment to track Julia initialization state
eam_julia_env <- new.env(parent = emptyenv())
eam_julia_env$julia_initialized <- FALSE

#' Initialize Julia Environment
#'
#' Initializes the Julia environment for ABI methods. This function is
#' reentrant and will only perform initialization once per R session.
#'
#' @note This function is not thread-safe. It assumes the caller is the main
#'   thread. All callers should document the Julia initialization side effect
#'   in their docstrings.
#'
#' @return Invisibly returns TRUE if initialization was performed, FALSE if
#'   already initialized.
#'
#' @keywords internal
init_julia_env <- function() {
  if (eam_julia_env$julia_initialized) {
    return(invisible(FALSE))
  }

  message("eam package: Activating Julia environment...")

  julia_env_path <- normalizePath(
    system.file("julia/env", package = "eam"),
    winslash = "/",
    mustWork = TRUE
  )
  JuliaConnectoR::juliaEval(paste(
    "using Pkg",
    sprintf("Pkg.activate(\"%s\")", julia_env_path),
    "Pkg.instantiate()",
    "using NeuralEstimators, Flux",
    sep = "\n"
  ))

  eam_julia_env$julia_initialized <- TRUE
  invisible(TRUE)
}
