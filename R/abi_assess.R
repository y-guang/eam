#' Assess neural estimator using ABI input
#'
#' A wrapper around \code{NeuralEstimators::assess()} that automatically unpacks
#' parameters and summary statistics from an ABI input object created by
#' \code{\link{build_abi_input}}.
#'
#' @param estimator A neural estimator to assess.
#'   See \code{NeuralEstimators::assess} for details.
#' @param abi_input An ABI input object created by \code{\link{build_abi_input}}.
#'   Must contain \code{theta_val}, \code{Z_val}, and \code{theta} elements.
#'   If \code{theta_test} and \code{Z_test} are available, they will be used;
#'   otherwise the validation set will be used for assessment.
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
#' This function requires the \code{NeuralEstimators} package to be installed.
#' If not available, the function will throw an error with installation instructions.
#'
#' This function extracts test or validation parameters and summary statistics
#' from the ABI input object, along with parameter names (\code{theta}), and
#' passes them to \code{NeuralEstimators::assess()}. If test set is available
#' (\code{theta_test} and \code{Z_test}), it will be used; otherwise the
#' validation set (\code{theta_val} and \code{Z_val}) will be used.
#'
#' The returned object has class \code{eam_abi_assess}, which enables the use of
#' S3 methods like \code{\link{plot_cv_recovery}} for visualization.
#'
#' @examples
#' \dontrun{
#' # Assuming you have a trained estimator and ABI input with test set
#' assessment <- abi_assess(
#'   estimator = estimator,
#'   abi_input = abi_input,
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
    estimator,
    abi_input,
    estimator_name = NULL,
    use_gpu = TRUE,
    verbose = TRUE) {
  # Check if NeuralEstimators package is available
  if (!requireNamespace("NeuralEstimators", quietly = TRUE)) {
    stop(
      "Package 'NeuralEstimators' is required for this function.\n",
      "Please install it via:\n",
      "  install.packages('NeuralEstimators')\n",
      call. = FALSE
    )
  }

  # Validate abi_input
  if (!is.list(abi_input)) {
    stop("abi_input must be a list")
  }

  required_elements <- c("theta_val", "Z_val", "theta")
  missing_elements <- setdiff(required_elements, names(abi_input))
  if (length(missing_elements) > 0) {
    stop(paste0(
      "abi_input must contain elements: ",
      paste(missing_elements, collapse = ", ")
    ))
  }

  # Check if test set is available, otherwise use validation set
  if ("theta_test" %in% names(abi_input) && "Z_test" %in% names(abi_input)) {
    theta_assess <- abi_input$theta_test
    Z_assess <- abi_input$Z_test
    if (verbose) {
      message("Using test set for assessment")
    }
  } else {
    theta_assess <- abi_input$theta_val
    Z_assess <- abi_input$Z_val
    if (verbose) {
      message("Test set not available, using validation set for assessment")
    }
  }

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
