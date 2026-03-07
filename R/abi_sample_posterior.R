#' Sample from posterior distribution using trained neural estimator
#'
#' A wrapper around \code{NeuralEstimators::sampleposterior()} that automatically
#' extracts the trained estimator from a trained estimator object created by
#' \code{\link{abi_train}} and returns posterior samples in a 3D array format.
#'
#' @param trained_estimator A trained estimator object returned by \code{\link{abi_train}}.
#'   Must be of class \code{eam_abi_trained_estimator} and contain a
#'   \code{trained_estimator} element.
#' @param Z Data in a format amenable to the neural-network architecture of
#'   estimator. Can be a single data set or a list of data sets. If NULL
#'   (default), uses \code{Z_test} from the ABI input object.
#' @param N Integer; number of approximate posterior samples to draw
#'   (default: 1000).
#' @param ... Additional keyword arguments passed to the Julia version of
#'   \code{sampleposterior()}, applicable when estimator is a
#'   likelihood-to-evidence-ratio estimator.
#'
#' @return A 3D array of class \code{eam_abi_posterior_samples} containing
#'   posterior samples with dimensions (parameters × samples × datasets), where
#'   the first dimension is the number of parameters, the second is N (number
#'   of samples), and the third is the number of data sets in Z. The first
#'   dimension is named using the parameter names from the ABI input.
#'
#' @details
#' This function extracts the trained neural posterior estimator from the
#' trained estimator object and uses it to sample from the approximate posterior
#' distribution given data Z. The samples are returned as a 3D array stacked
#' along the third dimension using Julia's \code{stack()} function.
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
#' # Sample from posterior using test data (default)
#' posterior_samples <- abi_sample_posterior(
#'   trained_estimator = trained_estimator,
#'   N = 1000
#' )
#'
#' # Sample from posterior for specific data
#' posterior_samples <- abi_sample_posterior(
#'   trained_estimator = trained_estimator,
#'   Z = abi_input$Z_test,
#'   N = 2000
#' )
#' }
#'
#' @export
abi_sample_posterior <- function(
    trained_estimator,
    Z = NULL,
    N = 1000,
    ...) {
  # Initialize Julia environment
  init_julia_env()

  # Validate trained_estimator
  if (!inherits(trained_estimator, "eam_abi_trained_estimator")) {
    stop("trained_estimator must be an object of class 'eam_abi_trained_estimator' returned by abi_train()")
  }

  # Use Z_test from abi_input if Z is not provided
  if (is.null(Z)) {
    if (is.null(trained_estimator$abi_input$Z_test)) {
      stop("Z is NULL and Z_test is not available in trained_estimator$abi_input")
    }
    Z <- trained_estimator$abi_input$Z_test
  }

  # Extract the actual trained estimator
  estimator <- trained_estimator$trained_estimator

  # Sample from posterior
  posterior_sample_vector_of_matrices <- NeuralEstimators::sampleposterior(
    estimator = estimator,
    Z = Z,
    N = N,
    ...
  )

  # Transfer to Julia global environment
  JuliaConnectoR::juliaLet(
    "global eam_internal_posterior_sample_vector_of_matrices = posterior_sample_vector_of_matrices",
    posterior_sample_vector_of_matrices = posterior_sample_vector_of_matrices
  )

  # Stack into 3D array using Julia
  posterior_sample_array <- JuliaConnectoR::juliaEval(
    "stack(eam_internal_posterior_sample_vector_of_matrices; dims=3)"
  )

  # Set parameter names on the first dimension
  param_names <- trained_estimator$abi_input$theta
  dimnames(posterior_sample_array) <- list(
    param_names,
    NULL,
    NULL
  )

  # Add class
  class(posterior_sample_array) <- c("eam_abi_posterior_samples", class(posterior_sample_array))

  return(posterior_sample_array)
}
