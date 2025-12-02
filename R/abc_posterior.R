#' Bootstrap resample ABC posterior samples
#'
#' @param abc_result An abc object from abc::abc
#' @param n_samples Number of bootstrap samples to draw (default 1000)
#' @param replace Logical, whether to sample with replacement (default TRUE)
#' @return Matrix of bootstrapped parameter values
#' @export
abc_posterior_bootstrap <- function(
    abc_result,
    n_samples,
    replace = TRUE) {
  if (!inherits(abc_result, "abc")) {
    stop("abc_result must be of class 'abc'")
  }

  params <- extract_abc_param_values(abc_result)

  # Check if we have enough samples for bootstrap without replacement
  n_available <- nrow(params)
  if (!replace && n_samples > n_available) {
    stop(
      "n_samples (", n_samples, ") cannot be larger than ",
      "available posterior samples (", n_available, ") when replace = FALSE"
    )
  }

  # Draw bootstrap sample indices
  sample_idx <- sample(n_available, n_samples, replace = replace)

  # Return bootstrapped parameter matrix
  params[sample_idx, , drop = FALSE]
}
