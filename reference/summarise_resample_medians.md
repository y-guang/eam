# Summarise resample medians

Calculate summary statistics for parameter medians across resample
iterations. Returns mean, median, and confidence intervals of the median
distributions.

## Usage

``` r
summarise_resample_medians(data, ..., ci_level = 0.95)
```

## Arguments

- data:

  List of abc results from abc_resample

- ...:

  Additional custom summary functions (named functions)

- ci_level:

  Confidence level for intervals (default 0.95)

## Value

Data frame with summary statistics for each parameter

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

# summarise the resample medians
summary_stats <- summarise_resample_medians(results, ci_level = 0.95)
print(summary_stats)
#>      parameter      mean    median ci_lower_0.025 ci_upper_0.975
#> 1     V_beta_1 0.2610199 0.2604535      0.2312461      0.2910537
#> 2 V_beta_group 0.1898724 0.1895129      0.1690189      0.2093823
```
