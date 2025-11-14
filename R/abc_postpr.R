#' ABC model comparison wrapper
#'
#' Wrapper function for abc::postpr to facilitate model comparison.
#'
#' @param sumstats A named list of summary statistics from different models
#' @param target Target summary statistics from observed data
#' @param ... Additional arguments passed to abc::postpr
#' @export
abc_postpr <- function(
    sumstats = list(),
    target,
    ...) {
  if (length(sumstats) < 2) {
    stop("At least 2 sumstats are required for model comparison")
  }

  # Extract model names from sumstats list
  model_names <- names(sumstats)
  if (is.null(model_names)) {
    model_names <- paste0("model_", seq_along(sumstats))
  }

  # Stack summary statistics and create index vector
  index_list <- list()

  for (i in seq_along(sumstats)) {
    # Create index vector for this model
    n_rows <- nrow(sumstats[[i]])
    index_list[[i]] <- rep(model_names[i], n_rows)
  }

  # Combine all summary statistics and indices
  sumstat <- do.call(rbind, sumstats)
  index <- unlist(index_list)

  # Call abc::postpr with all arguments
  abc::postpr(
    target = target,
    index = index,
    sumstat = sumstat,
    ...
  )
}
