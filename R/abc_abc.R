#' Approximate Bayesian Computation wrapper
#'
#' Wrapper around \code{\link[abc]{abc}} to perform ABC inference.
#' This function provides a consistent interface within the eam package
#' and encapsulates the dependency on the abc package.
#'
#' @param abc_input A list with components \code{target}, \code{param}, and \code{sumstat}
#'   (typically produced by \code{\link{build_abc_input}})
#' @param tol Tolerance level (0 to 1) for ABC acceptance
#' @param method ABC method: "rejection", "loclinear", "neuralnet", or "ridge"
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
