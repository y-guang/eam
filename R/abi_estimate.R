#' Estimate parameters using trained neural estimator
#'
#' A wrapper around \code{NeuralEstimators::estimate()} that automatically
#' extracts the trained estimator from a trained estimator object created by
#' \code{\link{abi_train}}.
#'
#' @param trained_estimator A trained estimator object returned by \code{\link{abi_train}}.
#'   Must be of class \code{eam_abi_trained_estimator} and contain a
#'   \code{trained_estimator} element.
#' @param Z Data in a format amenable to the neural-network architecture of
#'   estimator. Can be a single data set or a list of data sets.
#' @param X Additional inputs to the neural network (default: NULL).
#'   If provided, the call will be of the form \code{estimator((Z, X))}.
#' @param batchsize Integer; the batch size for applying estimator to Z
#'   (default: 32). Batching occurs only if Z is a list, indicating multiple
#'   data sets.
#' @param use_gpu Logical; whether to use the GPU if available (default: TRUE).
#'
#' @return A matrix of outputs resulting from applying the trained estimator
#'   to Z (and possibly X).
#'
#' @details
#' This function extracts the trained neural estimator from the trained
#' estimator object and applies it to the provided data Z. The data Z should
#' be in the same format as the summary statistics used during training
#' (e.g., \code{Z_train}, \code{Z_val}, or \code{Z_test} from the ABI input).
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
#' # Estimate parameters for test data
#' point_est <- abi_estimate(
#'   trained_estimator = trained_estimator,
#'   Z = abi_input$Z_test[[1]]
#' )
#'
#' # Estimate for multiple data sets
#' estimates <- abi_estimate(
#'   trained_estimator = trained_estimator,
#'   Z = abi_input$Z_test,
#'   batchsize = 16
#' )
#' }
#'
#' @export
abi_estimate <- function(
    trained_estimator,
    Z,
    X = NULL,
    batchsize = 32,
    use_gpu = TRUE) {
  # Initialize Julia environment
  init_julia_env()

  # Validate trained_estimator
  if (!inherits(trained_estimator, "eam_abi_trained_estimator")) {
    stop("trained_estimator must be an object of class 'eam_abi_trained_estimator' returned by abi_train()")
  }

  # Extract the actual trained estimator
  estimator <- trained_estimator$trained_estimator

  # Call NeuralEstimators::estimate
  result <- NeuralEstimators::estimate(
    estimator = estimator,
    Z = Z,
    X = X,
    batchsize = batchsize,
    use_gpu = use_gpu
  )

  return(result)
}
