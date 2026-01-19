# Plot resample forest plots

Create forest plots showing parameter ranges across resample iterations.
Each iteration is displayed as a horizontal line with quantile
intervals.

## Usage

``` r
plot_resample_forest(
  data,
  n_rows = 2,
  n_cols = 2,
  interactive = FALSE,
  ci_level = 0.95
)
```

## Arguments

- data:

  List of abc results from abc_resample

- n_rows:

  Number of rows in plot grid (default 2)

- n_cols:

  Number of columns in plot grid (default 2)

- interactive:

  Whether to pause between pages (default FALSE)

- ci_level:

  quantile intervals (default 0.95 for 95% interval)

## Value

No return value, called for side effects (plotting). Creates forest
plots displayed in the graphics device.

## Examples

``` r
# Load ABC input data from example simulation
abc_input <- readRDS(
  system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
)

# Perform ABC resampling
results <- abc_resample(
  target = abc_input$target,
  param = abc_input$param,
  sumstat = abc_input$sumstat,
  n_iterations = 100,
  n_samples = 100,
  tol = 0.5,
  method = "rejection"
)

# plot forest plots showing parameter ranges
plot_resample_forest(results, ci_level = 0.95)
```
