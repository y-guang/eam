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
#> Warning: cannot open compressed file '', probable reason 'No such file or directory'
#> Error in gzfile(file, "rb"): cannot open the connection

# Summarise posterior distributions
summarise_posterior_parameters(abc_rejection_model)
#> Error: object 'abc_rejection_model' not found

# Custom confidence interval level
summarise_posterior_parameters(abc_rejection_model, ci_level = 0.90)
#> Error: object 'abc_rejection_model' not found
```
