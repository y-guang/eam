#' Summarise data by groups with optional pivoting
#'
#' This function provides a flexible way to group data, compute summary statistics,
#' and reshape results. It works similar to `dplyr::summarise()` but with added
#' capabilities for pivoting results wider.
#'
#' You can use `summarise_by()` in two ways:
#' 1. **Direct use**: Pass your data directly and get results immediately
#' 2. **Build-then-apply**: Create reusable summary functions, combine them with `+`,
#'    then apply to your data later
#'
#' The build-then-apply approach is useful when you want to compute different types
#' of summaries (e.g., RT statistics and accuracy statistics) and automatically join
#' them together.
#'
#' @section Usage with ABC workflows:
#' If you plan to use \code{\link{build_abc_input}} for ABC analysis, you must use
#' \code{summarise_by()} to generate summary statistics (or manually handle the arrow
#' output format). This function typically works together with \code{\link{map_by_condition}}
#' to process simulation results. See \code{\link{map_by_condition}} for workflow examples.
#'
#' @param .data A data frame to summarise, or NULL to create a reusable summary function
#' @param ... Summary expressions using dplyr-style syntax. Named arguments become
#'   column names in the output (e.g., `mean_rt = mean(rt)`).
#' @param .by Character vector of grouping column names. Default is "condition_idx".
#' @param .wider_by Character vector of columns to keep as identifiers when pivoting.
#'   Default is "condition_idx". Must be a subset of `.by`. When `.wider_by` differs
#'   from `.by`, the extra columns in `.by` will be spread across as column suffixes.
#'
#' @return
#' - If `.data` is provided: A data frame with summarised results
#' - If `.data` is NULL: A function that can be applied to data later
#'
#' @examples
#' # Example 1: Direct use - pass data and get results immediately
#' trial_data <- data.frame(
#'   condition_idx = rep(1:2, each = 4),
#'   item_idx = rep(1:2, 4),
#'   rt = c(0.5, 0.6, 0.7, 0.8, 0.55, 0.65, 0.75, 0.85),
#'   accuracy = c(1, 1, 0, 1, 1, 0, 1, 1)
#' )
#'
#' # Compute mean RT and accuracy by condition and item
#' result <- summarise_by(
#'   trial_data,
#'   mean_rt = mean(rt),
#'   mean_acc = mean(accuracy),
#'   .by = c("condition_idx", "item_idx"),
#'   .wider_by = "condition_idx"
#' )
#' # Result has columns: condition_idx, mean_rt_item_idx_1, mean_rt_item_idx_2, etc.
#' result
#'
#' # Example 2: Build-then-apply - create reusable summary functions
#' # Build separate summary functions for different statistics
#' rt_summary_pipe <- summarise_by(
#'   mean_rt = mean(rt),
#'   sd_rt = stats::sd(rt),
#'   .by = c("condition_idx", "item_idx"),
#'   .wider_by = "condition_idx"
#' )
#'
#' acc_summary_pipe <- summarise_by(
#'   mean_acc = mean(accuracy),
#'   n_trials = length(accuracy),
#'   .by = c("condition_idx", "item_idx"),
#'   .wider_by = "condition_idx"
#' )
#'
#' # Combine with + and apply to data
#' combined_summary_pipe <- rt_summary_pipe + acc_summary_pipe
#' result <- combined_summary_pipe(trial_data)
#' # Result has all summaries joined by condition_idx
#' result
#'
#' @export
summarise_by <- function(
    .data = NULL,
    ...,
    .by = c("condition_idx"),
    .wider_by = c("condition_idx")) {
  dots <- rlang::enquos(...)

  # If .data is missing or NULL, return a spec object for delayed evaluation
  if (is.null(.data)) {
    spec_list <- list(
      list(
        dots = dots,
        .by = .by,
        .wider_by = .wider_by
      )
    )

    # Create a function that captures the spec and can be called directly
    spec <- function(.data) {
      apply_summarise_by_spec(spec_list, .data)
    }

    # Attach the spec_list as an attribute and set the class
    attr(spec, "spec_list") <- spec_list
    class(spec) <- c("eam_summarise_by_spec", "function")

    return(spec)
  }

  # Use the shared implementation
  summarise_by_impl(.data, dots, .by, .wider_by)
}


#' Internal function to perform the core summarise_by logic
#'
#' @param .data A data frame to summarise
#' @param dots Quosures containing the summary expressions
#' @param .by Character vector of column names to group by
#' @param .wider_by Character vector of column names to keep as identifying columns
#' @return A data frame with class "eam_summarise_by_tbl"
#' @keywords internal
summarise_by_impl <- function(.data, dots, .by, .wider_by) {
  # Early return for empty data frames
  if (nrow(.data) == 0) {
    # Return a completely empty data frame with proper class
    result_df <- data.frame()
    class(result_df) <- c("eam_summarise_by_tbl", class(result_df))
    attr(result_df, "wider_by") <- .wider_by
    return(result_df)
  }
  
  # Validate that .wider_by is a subset of .by
  if (!all(.wider_by %in% .by)) {
    stop(
      ".wider_by must be a subset of .by.\n",
      "  .by = c(", paste0('"', .by, '"', collapse = ", "), ")\n",
      "  .wider_by = c(", paste0('"', .wider_by, '"', collapse = ", "), ")\n",
      "  Invalid columns in .wider_by: ",
      paste0('"', setdiff(.wider_by, .by), '"', collapse = ", ")
    )
  }

  # group_by
  grouped <- if (is.null(.by)) {
    list(.data)
  } else {
    dplyr::group_split(.data, dplyr::across(dplyr::all_of(.by)))
  }

  # evaluate - use lapply for better performance, then bind efficiently
  result_list <- lapply(grouped, function(sub_df) {
    # Extract key values efficiently (group_split returns ungrouped data)
    key_vals <- if (is.null(.by)) {
      list()
    } else {
      # Direct extraction from first row - much faster
      stats::setNames(
        lapply(.by, function(col) sub_df[[col]][1]),
        .by
      )
    }

    vals <- purrr::imap(dots, function(expr, name) {
      # Use the assigned name directly if provided, not the expression text
      colname <- name

      val <- rlang::eval_tidy(expr, data = sub_df)

      # Check length first (faster for atomic vectors)
      if (length(val) > 1 || is.list(val)) {
        nm <- names(val)
        if (is.null(nm) || any(!nzchar(nm))) {
          # No names or empty names: use X1, X2, etc.
          nm <- paste0(colname, "_X", seq_along(val))
        } else {
          # Has names: repair names them, then prefix
          nm_clean <- vctrs::vec_as_names(nm, repair = "universal", quiet = TRUE)
          nm <- paste0(colname, "_", nm_clean)
        }
        stats::setNames(as.list(val), nm)
      } else {
        stats::setNames(list(val), colname)
      }
    }) |> purrr::flatten()

    c(key_vals, vals)
  })
  result_df <- dplyr::bind_rows(result_list)

  # Pivot wider if .by and .wider_by are different
  pivot_cols <- setdiff(.by, .wider_by)

  if (length(pivot_cols) > 0) {
    # Get all value columns (not in .by)
    value_cols <- setdiff(names(result_df), .by)

    # Create a combined column for pivoting with structured names
    # e.g., "item_idx_1", "item_idx_2"
    result_df$.pivot_key <- do.call(
      paste,
      c(
        lapply(pivot_cols, function(col) paste0(col, "_", result_df[[col]])),
        list(sep = "_")
      )
    )

    # Pivot wider: spread pivot_cols across columns
    result_df <- tidyr::pivot_wider(
      result_df,
      id_cols = dplyr::all_of(.wider_by),
      names_from = ".pivot_key",
      values_from = dplyr::all_of(value_cols),
      names_sep = "_"
    )
  }

  # assign the class and store .wider_by as attribute
  class(result_df) <- c("eam_summarise_by_tbl", class(result_df))
  attr(result_df, "wider_by") <- .wider_by

  result_df
}

#' Join two eam_summarise_by_tbl objects
#'
#' S3 method for the + operator to join two summary tables created by
#' \code{summarise_by}. Tables must have identical .wider_by attributes
#' to be joined.
#'
#' @param e1 First eam_summarise_by_tbl object
#' @param e2 Second eam_summarise_by_tbl object
#' @return A joined data frame with class "eam_summarise_by_tbl",
#'   preserving the .wider_by attribute from the input tables
#' @export
`+.eam_summarise_by_tbl` <- function(e1, e2) {
  # Only process if both are eam_summarise_by_tbl
  if (!inherits(e1, "eam_summarise_by_tbl") ||
    !inherits(e2, "eam_summarise_by_tbl")) {
    # Not our class duty - fall back to default
    return(NextMethod("+"))
  }

  # Get .wider_by from both tables
  wider_by_1 <- attr(e1, "wider_by")
  wider_by_2 <- attr(e2, "wider_by")

  # Check if .wider_by attributes are identical
  if (!identical(wider_by_1, wider_by_2)) {
    stop(
      "Cannot join tables with different .wider_by attributes.\n",
      "  Table 1 .wider_by: c(",
      paste0('"', wider_by_1, '"', collapse = ", "), ")\n",
      "  Table 2 .wider_by: c(",
      paste0('"', wider_by_2, '"', collapse = ", "), ")\n",
      "  Both tables must have the same .wider_by for joining."
    )
  }

  # Handle empty tables
  n1 <- nrow(e1)
  n2 <- nrow(e2)
  
  if (n1 == 0 && n2 == 0) return(e1)
  if (n1 == 0) return(e2)
  if (n2 == 0) return(e1)

  # Join the two tables by the .wider_by columns
  result <- dplyr::full_join(e1, e2, by = wider_by_1)

  # Preserve the class and .wider_by attribute
  class(result) <- c("eam_summarise_by_tbl", class(result))
  attr(result, "wider_by") <- wider_by_1

  result
}

#' @export
print.eam_summarise_by_spec <- function(x, ...) {
  spec_list <- attr(x, "spec_list")
  cat("<eam_summarise_by_spec>\n")
  cat("Number of summarise operations:", length(spec_list), "\n")
  for (i in seq_along(spec_list)) {
    cat("\nOperation", i, ":\n")
    cat("  .by:", paste(spec_list[[i]]$.by, collapse = ", "), "\n")
    cat("  .wider_by:", paste(spec_list[[i]]$.wider_by, collapse = ", "), "\n")
    cat("  Summary expressions:", length(spec_list[[i]]$dots), "\n")
  }
  invisible(x)
}

#' Internal function to apply a spec to data
#'
#' @param spec_list A list of spec operations (the internal spec list)
#' @param .data A data frame
#' @return A data frame with class "eam_summarise_by_tbl"
#' @keywords internal
apply_summarise_by_spec <- function(spec_list, .data) {
  # Apply each summarise_by operation and combine with +
  results <- lapply(spec_list, function(op) {
    # Use the shared implementation
    summarise_by_impl(.data, op$dots, op$.by, op$.wider_by)
  })

  # Combine results using the + operator
  if (length(results) == 1) {
    return(results[[1]])
  }

  result <- results[[1]]
  for (i in 2:length(results)) {
    result <- result + results[[i]]
  }

  result
}

#' Add two summarise_by specs together
#'
#' S3 method for the + operator to combine two `eam_summarise_by_spec`
#' objects into a single spec that will apply both operations.
#'
#' @param e1 First eam_summarise_by_spec or eam_summarise_by_tbl object
#' @param e2 Second eam_summarise_by_spec or eam_summarise_by_tbl object
#' @return A combined eam_summarise_by_spec object
#' @export
`+.eam_summarise_by_spec` <- function(e1, e2) {
  # Handle spec + spec
  if (inherits(e1, "eam_summarise_by_spec") &&
    inherits(e2, "eam_summarise_by_spec")) {
    # Extract the spec lists from both
    spec_list1 <- attr(e1, "spec_list")
    spec_list2 <- attr(e2, "spec_list")

    # Combine the spec lists
    combined_spec_list <- c(spec_list1, spec_list2)

    # Create a new function that applies both specs
    result <- function(.data) {
      apply_summarise_by_spec(combined_spec_list, .data)
    }

    # Attach the combined spec list and set the class
    attr(result, "spec_list") <- combined_spec_list
    class(result) <- c("eam_summarise_by_spec", "function")

    return(result)
  }

  # If one is not a spec, fall back to default
  NextMethod("+")
}
