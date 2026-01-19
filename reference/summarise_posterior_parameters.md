# Summarise posterior parameter distributions

Compute summary statistics (mean, median, confidence intervals) for
posterior parameters from ABC results.

## Usage

``` r
summarise_posterior_parameters(data, ...)

# S3 method for class 'abc'
summarise_posterior_parameters(data, ..., ci_level = 0.95)
```

## Arguments

- data:

  An `abc` object containing posterior samples in `adj.values` or
  `unadj.values`.

- ...:

  Additional arguments for custom summary functions. Functions passed as
  named arguments will be applied to each parameter's posterior samples.

- ci_level:

  Numeric; confidence interval level (default: 0.95).

## Value

A data frame with summary statistics for each parameter.

## See also

`summarise_posterior_parameters.abc`

## Examples

``` r
# Load ABC output from saved file
abc_file <- system.file(
  "extdata", "rdm_minimal", "abc", "abc_rejection_model.rds",
  package = "eam"
)
abc_rejection_model <- readRDS(abc_file)

# Summarise posterior distributions
summarise_posterior_parameters(abc_rejection_model)
#>      parameter      mean    median ci_lower_0.025 ci_upper_0.975
#> 1     V_beta_1 0.2684096 0.2607152      0.1119190      0.4470107
#> 2 V_beta_group 0.1949098 0.1879120      0.1036883      0.2958763

# Custom confidence interval level
summarise_posterior_parameters(abc_rejection_model, ci_level = 0.90)
#>      parameter      mean    median ci_lower_0.050 ci_upper_0.950
#> 1     V_beta_1 0.2684096 0.2607152      0.1291406       0.422611
#> 2 V_beta_group 0.1949098 0.1879120      0.1070319       0.290407
```
