#' Assess neural estimator using trained estimator
#'
#' A wrapper around \code{NeuralEstimators::assess()} that automatically unpacks
#' the trained estimator and ABI input from a trained estimator object created by
#' \code{\link{abi_train}}.
#'
#' @param trained_estimator A trained estimator object returned by \code{\link{abi_train}}.
#'   Must be of class \code{eam_abi_trained_estimator} and contain
#'   \code{trained_estimator} and \code{abi_input} elements.
#' @param estimator_name Character string; optional name for the estimator (default: NULL).
#' @param use_gpu Logical; whether to use GPU for assessment (default: TRUE).
#' @param verbose Logical; whether to print progress information (default: TRUE).
#'
#' @return A list with class \code{eam_abi_assess} containing:
#' \describe{
#'   \item{estimates}{Data frame with columns: m, k, j, estimator, parameter, estimate, truth}
#'   \item{runtimes}{Data frame with runtime information}
#' }
#'
#' @details
#' This function extracts the trained estimator and ABI input from the trained
#' estimator object, then extracts test parameters and summary statistics
#' from the ABI input, along with parameter names (\code{theta}), and passes them
#' to \code{NeuralEstimators::assess()}. The test set (\code{theta_test} and
#' \code{Z_test}) is used for assessment.
#'
#' The returned object has class \code{eam_abi_assess}, which enables the use of
#' S3 methods like \code{\link{plot_cv_recovery}} for visualization.
#'
#' @note This function initializes the global Julia environment on first call.
#'
#' @examples
#' \dontrun{
#' # Train an estimator first
#' trained_estimator <- abi_train(
#'   estimator = estimator,
#'   abi_input = abi_input,
#'   epochs = 100
#' )
#'
#' # Assess the trained estimator
#' assessment <- abi_assess(
#'   trained_estimator = trained_estimator,
#'   estimator_name = "MyEstimator",
#'   use_gpu = TRUE,
#'   verbose = TRUE
#' )
#'
#' # View the assessment results
#' str(assessment)
#'
#' # Plot parameter recovery
#' plot_cv_recovery(assessment)
#' }
#'
#' @export
abi_assess <- function(
    trained_estimator,
    estimator_name = NULL,
    use_gpu = TRUE,
    verbose = TRUE) {
  # Initialize Julia environment
  init_julia_env()

  # Validate trained_estimator
  if (!inherits(trained_estimator, "eam_abi_trained_estimator")) {
    stop("trained_estimator must be an object of class 'eam_abi_trained_estimator' returned by abi_train()")
  }

  # Extract trained estimator and abi_input from trained_estimator object
  estimator <- trained_estimator$trained_estimator
  abi_input <- trained_estimator$abi_input

  # Validate abi_input
  if (!inherits(abi_input, "eam_abi_input")) {
    stop("abi_input must be an object of class 'eam_abi_input' created by build_abi_input()")
  }

  # Use test set for assessment
  theta_assess <- abi_input$theta_test
  Z_assess <- abi_input$Z_test

  # Extract parameter names from abi_input
  parameter_names <- abi_input$theta

  # Call NeuralEstimators::assess
  result <- NeuralEstimators::assess(
    estimators = estimator,
    parameters = theta_assess,
    Z = Z_assess,
    estimator_names = estimator_name,
    parameter_names = parameter_names,
    use_gpu = use_gpu,
    verbose = verbose
  )

  # Add eam_assess class
  class(result) <- c("eam_abi_assess", class(result))

  return(result)
}
