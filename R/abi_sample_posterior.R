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
#' @return A tibble of class \code{eam_abi_posterior_samples} containing
#'   posterior samples. Each row represents one posterior sample for one dataset.
#'   Columns include \code{dataset_id} (integer dataset identifier) and one
#'   column for each parameter.
#'
#' @details
#' This function extracts the trained neural posterior estimator from the
#' trained estimator object and uses it to sample from the approximate posterior
#' distribution given data Z. The samples are stacked using Julia's
#' \code{stack()} function, then converted to a tibble in R for easy
#' manipulation and summarization.
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

  # Stack into 3D array using Julia (params × samples × datasets)
  posterior_sample_array <- JuliaConnectoR::juliaEval(
    "stack(eam_internal_posterior_sample_vector_of_matrices; dims=3)"
  )

  # Get parameter names and dimensions
  param_names <- trained_estimator$abi_input$theta
  n_datasets <- dim(posterior_sample_array)[3]

  # Convert 3D array to tibble format
  # Structure: each row is one sample for one dataset
  samples_list <- list()

  for (i in seq_len(n_datasets)) {
    # Extract samples for this dataset: params × samples
    dataset_samples <- posterior_sample_array[, , i]

    # Transpose to samples × params and convert to data frame
    df <- as.data.frame(t(dataset_samples))
    colnames(df) <- param_names

    # Add dataset identifier
    df$dataset_id <- i

    samples_list[[i]] <- df
  }

  # Combine all datasets into one tibble
  samples_tbl <- dplyr::bind_rows(samples_list)

  # Reorder columns to put dataset_id first
  col_order <- c("dataset_id", setdiff(names(samples_tbl), "dataset_id"))
  samples_tbl <- samples_tbl[, col_order]

  # Convert to tibble and add class
  samples_tbl <- tibble::as_tibble(samples_tbl)
  class(samples_tbl) <- c("eam_abi_posterior_samples", class(samples_tbl))

  return(samples_tbl)
}
