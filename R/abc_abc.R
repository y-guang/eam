#' Approximate Bayesian Computation wrapper
#'
#' Wrapper around \code{\link[abc]{abc}} to perform ABC inference.
#' This function provides a consistent interface within the eam package
#' and encapsulates the dependency on the abc package.
#'
#' @param abc_input A list with components \code{target}, \code{param}, and \code{sumstat}
#'   (typically produced by \code{\link{build_abc_input}})
#' @param tol Tolerance level (0 to 1) for ABC acceptance
#' @param method ABC method: "rejection", "loclinear", "neuralnet"
#' @param transf Transformations to apply to parameters: "none" (default), "log", or "logit"
#' @param ... Additional arguments passed to \code{\link[abc]{abc}}
#'
#' @return An object of class \code{abc} from \code{\link[abc]{abc}}
#'
#' @details
#' This is a thin wrapper around the \code{abc::abc()} function.
#' Users should refer to the abc package documentation for detailed parameter
#' descriptions and options.
#'
#' @examples
#' \donttest{
#' # Load example simulation output and observed data
#' rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
#' sim_output <- load_simulation_output(file.path(rdm_minimal_example, "simulation"))
#' obs_df <- read.csv(file.path(rdm_minimal_example, "observation", "observation_data.csv"))
#'
#' # Define a summary-statistics pipeline
#' summary_pipe <- summarise_by(
#'   .by = c("condition_idx"),
#'   rt_mean = mean(rt)
#' )
#'
#' # Summarise simulation output and observed data
#' sim_summary <- map_by_condition(
#'   sim_output,
#'   .progress = FALSE,
#'   .parallel = FALSE,
#'   function(cond_df) {
#'     summary_pipe(cond_df)
#'   }
#' )
#' obs_summary <- summary_pipe(obs_df)
#'
#' # Build ABC input
#' abc_input <- build_abc_input(
#'   simulation_output = sim_output,
#'   simulation_summary = sim_summary,
#'   target_summary = obs_summary,
#'   param = c("V_beta_1", "V_beta_group")
#' )
#'
#' # Fit an ABC model
#' abc_rejection_model <- abc_abc(
#'   abc_input = abc_input,
#'   tol = 0.5,
#'   method = "rejection"
#' )
#' }
#'
#' @export
abc_abc <- function(abc_input, tol, method, transf = "none", ...) {
  abc::abc(
    target = abc_input$target,
    param = abc_input$param,
    sumstat = abc_input$sumstat,
    tol = tol,
    method = method,
    transf = transf,
    ...
  )
}
