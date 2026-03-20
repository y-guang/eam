#' Cross-validation for ABC model
#'
#' Wrapper around \code{\link[abc]{cv4abc}} to perform cross-validation of ABC results.
#' This function provides a consistent interface within the eam package
#' and encapsulates the dependency on the abc package.
#'
#' @param abc_input A list with components \code{param} and \code{sumstat}
#'   (typically produced by \code{\link{build_abc_input}})
#' @param abc_result Fitted ABC model from \code{\link{abc_abc}}. Parameters like
#'   \code{method}, \code{transf}, etc. are extracted from this object.
#' @param nval Number of cross-validation folds
#' @param tols Tolerance levels to test during cross-validation
#' @param ... Additional arguments passed to \code{\link[abc]{cv4abc}}
#'
#' @return A cross-validation object from \code{\link[abc]{cv4abc}}
#'
#' @details
#' This is a thin wrapper around the \code{abc::cv4abc()} function.
#' When \code{abc_result} is provided, cv4abc extracts the method, transf,
#' and other settings from the fitted ABC object.
#' Users should refer to the abc package documentation for detailed parameter
#' descriptions and options.
#'
#' @export
abc_cv <- function(abc_input, abc_result, nval, tols, ...) {
  abc::cv4abc(
    param = abc_input$param,
    sumstat = abc_input$sumstat,
    abc.out = abc_result,
    nval = nval,
    tols = tols,
    ...
  )
}
