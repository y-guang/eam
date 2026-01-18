# Plot resample median distributions

Plot density distributions of parameter medians across resample
iterations.

## Usage

``` r
plot_resample_medians(data, n_rows = 2, n_cols = 2, interactive = FALSE)
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

## Value

No return value, called for side effects (plotting). Creates density
plots displayed in the graphics device.

## Examples

``` r
# Load ABC input data from example simulation
abc_input <- readRDS(
  system.file("extdata", "rdm_minimal", "abc", "abc_input.rds", package = "eam")
)
#> Warning: cannot open compressed file '', probable reason 'No such file or directory'
#> Error in gzfile(file, "rb"): cannot open the connection

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
#> Error: object 'abc_input' not found

# plot the resample medians for each parameter
plot_resample_medians(results)
#> Error: object 'results' not found
```
