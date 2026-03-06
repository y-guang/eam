#' Train neural estimator using ABI input
#'
#' A wrapper around \code{NeuralEstimators::train()} that automatically unpacks
#' parameters and summary statistics from an ABI input object created by
#' \code{\link{build_abi_input}}.
#'
#' @param estimator A neural estimator to train, or a character string of Julia
#'   code that evaluates to an estimator.
#'   See \code{NeuralEstimators::train} for details.
#' @param abi_input An ABI input object created by \code{\link{build_abi_input}}.
#'   Must contain \code{theta_train}, \code{Z_train}, \code{theta_val}, and
#'   \code{Z_val} elements.
#' @param train_subset Character string specifying which subset to use for
#'   training: "train", "val", or "test" (default: "train").
#' @param val_subset Character string specifying which subset to use for
#'   validation: "train", "val", or "test" (default: "val").
#' @param loss Character string specifying the loss function: 'absolute-error'
#'   for mean-absolute-error loss or 'squared-error' for mean-squared-error
#'   loss (default: 'absolute-error'). Can also be a string of Julia code
#'   defining a custom loss function.
#' @param learning_rate Numeric; learning rate for the ADAM optimizer
#'   (default: 1e-4).
#' @param epochs Integer; number of training epochs (default: 100).
#' @param batchsize Integer; batch size for stochastic gradient descent
#'   (default: 32).
#' @param savepath Character string; path to save the trained estimator and
#'   training information. If NULL (default), nothing is saved.
#' @param stopping_epochs Integer; stop training if validation risk doesn't
#'   improve for this many epochs (default: 5).
#' @param use_gpu Logical; whether to use GPU if available (default: TRUE).
#' @param verbose Logical; whether to print training information (default: TRUE).
#' @param ... Additional arguments passed to \code{NeuralEstimators::train()}.
#'
#' @return A list with class \code{eam_abi_trained_estimator} containing:
#' \describe{
#'   \item{original_estimator}{The initial estimator before training}
#'   \item{trained_estimator}{The trained neural estimator}
#'   \item{abi_input}{The ABI input object used for training}
#' }
#'
#' @details
#' This function extracts training and validation parameters and summary
#' statistics from the ABI input object and passes them to
#' \code{NeuralEstimators::train()}. The training data (\code{theta_train} and
#' \code{Z_train}) are used for updating the estimator via stochastic gradient
#' descent, while the validation data (\code{theta_val} and \code{Z_val}) are
#' used for monitoring performance and early stopping.
#'
#' If \code{savepath} is provided, the neural network parameters will be saved
#' as BSON files during training, along with loss values in
#' \code{loss_per_epoch.csv} and the best parameters in \code{best_network.bson}.
#'
#' @note This function initializes the global Julia environment on first call.
#'
#' @examples
#' \dontrun{
#' # Train a neural estimator with ABI input
#' trained_estimator <- abi_train(
#'   estimator = estimator,
#'   abi_input = abi_input,
#'   epochs = 100,
#'   learning_rate = 1e-4,
#'   batchsize = 32,
#'   use_gpu = TRUE
#' )
#'
#' # Train with custom save path
#' trained_estimator <- abi_train(
#'   estimator = estimator,
#'   abi_input = abi_input,
#'   epochs = 200,
#'   savepath = "path/to/save"
#' )
#' }
#'
#' @export
abi_train <- function(
    estimator,
    abi_input,
    train_subset = "train",
    val_subset = "val",
    loss = "absolute-error",
    learning_rate = 1e-4,
    epochs = 100,
    batchsize = 32,
    savepath = NULL,
    stopping_epochs = 5,
    use_gpu = TRUE,
    verbose = TRUE,
    ...) {
  # Initialize Julia environment
  init_julia_env()

  # Validate abi_input
  if (!inherits(abi_input, "eam_abi_input")) {
    stop("abi_input must be an object of class 'eam_abi_input' created by build_abi_input()")
  }

  # Validate subset parameters
  valid_subsets <- c("train", "val", "test")
  if (!train_subset %in% valid_subsets) {
    stop("train_subset must be one of: ", paste(valid_subsets, collapse = ", "))
  }
  if (!val_subset %in% valid_subsets) {
    stop("val_subset must be one of: ", paste(valid_subsets, collapse = ", "))
  }

  # Check if test subset is requested but not available
  if ((train_subset == "test" || val_subset == "test") && 
      (is.null(abi_input$theta_test) || is.null(abi_input$Z_test))) {
    stop("test subset requested but not available in abi_input")
  }

  # Handle estimator as string (Julia code)
  if (is.character(estimator) && length(estimator) == 1L) {
    estimator <- JuliaConnectoR::juliaEval(estimator)
  }

  # Store the original estimator
  original_estimator <- estimator

  # Extract training data based on train_subset
  theta_train <- switch(train_subset,
    train = abi_input$theta_train,
    val = abi_input$theta_val,
    test = abi_input$theta_test
  )
  Z_train <- switch(train_subset,
    train = abi_input$Z_train,
    val = abi_input$Z_val,
    test = abi_input$Z_test
  )

  # Extract validation data based on val_subset
  theta_val <- switch(val_subset,
    train = abi_input$theta_train,
    val = abi_input$theta_val,
    test = abi_input$theta_test
  )
  Z_val <- switch(val_subset,
    train = abi_input$Z_train,
    val = abi_input$Z_val,
    test = abi_input$Z_test
  )

  # Call NeuralEstimators::train
  trained_estimator <- NeuralEstimators::train(
    estimator = estimator,
    theta_train = theta_train,
    Z_train = Z_train,
    theta_val = theta_val,
    Z_val = Z_val,
    loss = loss,
    learning_rate = learning_rate,
    epochs = epochs,
    batchsize = batchsize,
    savepath = savepath,
    stopping_epochs = stopping_epochs,
    use_gpu = use_gpu,
    verbose = verbose,
    ...
  )

  # Build output list
  result <- list(
    original_estimator = original_estimator,
    trained_estimator = trained_estimator,
    abi_input = abi_input
  )

  class(result) <- c("eam_abi_trained_estimator", "list")

  return(result)
}
