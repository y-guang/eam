#' ABC model comparison wrapper
#'
#' Wrapper function for \code{\link[abc]{postpr}} to facilitate model comparison.
#' This function simplifies the process of comparing multiple models using ABC by
#' automatically stacking summary statistics and creating model indices.
#'
#' @param sumstats A named list of summary statistics matrices from different models.
#'   Each element should be a matrix or data frame with the same columns.
#' @param target Target summary statistics from observed data (vector or matrix)
#' @param ... Additional arguments passed to \code{\link[abc]{postpr}}
#' @return An object of class "postpr" from \code{\link[abc]{postpr}}
#' @examples
#' # Load pre-computed ABC input for model comparison
#' # This example compares the same model to itself for demonstration
#' rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
#' abc_input <- readRDS(file.path(rdm_minimal_example, "abc", "abc_input.rds"))
#'
#' # Compare two models using their summary statistics
#' # In practice, create different abc_input objects for different models:
#' # abc_input_1 <- build_abc_input(..., simulation_summary = sim_summary_1, ...)
#' # abc_input_2 <- build_abc_input(..., simulation_summary = sim_summary_2, ...)
#' postpr_result <- abc_postpr(
#'   sumstats = list(model1 = abc_input$sumstat, model2 = abc_input$sumstat),
#'   target = abc_input$target,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#'
#' # View model comparison results
#' summary(postpr_result)
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
