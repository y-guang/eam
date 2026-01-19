#!/usr/bin/env Rscript

#' Knit Pre-compiled Vignettes
#'
#' This script finds all *.Rmd.orig files in the vignettes directory
#' and knits them to their corresponding *.Rmd files.
#'
#' @param lazy Logical. If TRUE (default), skip files where the .Rmd output
#'   is newer than the .Rmd.orig source.

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
lazy <- TRUE

if (length(args) > 0) {
  if (tolower(args[1]) %in% c("false", "f", "no", "n", "0")) {
    lazy <- FALSE
  }
}

# Save current working directory
old_wd <- getwd()

# Ensure we're in the package root
if (basename(getwd()) != "eam") {
  # Try to find package root
  if (file.exists("eam.Rproj")) {
    # Already in root
  } else if (file.exists("../eam.Rproj")) {
    setwd("..")
  } else {
    stop("Cannot find package root. Please run from package directory.")
  }
}

# Change to vignettes directory
vignettes_dir <- "vignettes"
if (!dir.exists(vignettes_dir)) {
  stop("Vignettes directory not found: ", vignettes_dir)
}

setwd(vignettes_dir)

# Find all .Rmd.orig files
orig_files <- list.files(pattern = "\\.Rmd\\.orig$", full.names = FALSE)

if (length(orig_files) == 0) {
  message("No .Rmd.orig files found in vignettes directory.")
  setwd(old_wd)
  quit(save = "no", status = 0)
}

message("Found ", length(orig_files), " .Rmd.orig file(s)")

# Process each file
for (orig_file in orig_files) {
  # Determine output file name
  output_file <- sub("\\.Rmd\\.orig$", ".Rmd", orig_file)
  
  # Check if we should skip (lazy mode)
  skip <- FALSE
  if (lazy && file.exists(output_file)) {
    orig_mtime <- file.info(orig_file)$mtime
    output_mtime <- file.info(output_file)$mtime
    
    if (output_mtime > orig_mtime) {
      message("Skipping ", orig_file, " (output is newer)")
      skip <- TRUE
    }
  }
  
  if (!skip) {
    message("Knitting ", orig_file, " -> ", output_file)
    
    tryCatch({
      knitr::knit(
        input = orig_file,
        output = output_file,
        quiet = FALSE
      )
      message("Successfully knitted ", orig_file)
    }, error = function(e) {
      warning("Failed to knit ", orig_file, ": ", e$message)
    })
  }
}

# Restore working directory
setwd(old_wd)

message("Done!")
