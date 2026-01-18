# Plot CV parameter pair correlations

Create a matrix of pairwise plots for cross-validation parameter
estimates, including scatter plots with fitted trends, rank
correlations, and marginal distributions.

## Usage

``` r
plot_cv_pair_correlation(data, ...)

# S3 method for class 'cv4abc'
plot_cv_pair_correlation(data, ...)
```

## Arguments

- data:

  A `cv4abc` object containing true parameters and cross-validated
  estimates.

- ...:

  Additional arguments:

  interactive

  :   Logical; whether to pause between tolerance levels and wait for
      input

## Value

Invisibly returns \`NULL\`. Called for its side effect of producing
plots.

## See also

`plot_cv_pair_correlation.cv4abc`

## Examples

``` r
# Load CV output from saved file
cv_file <- system.file(
  "extdata", "rdm_minimal", "abc", "cv", "neuralnet.rds",
  package = "eam"
)
abc_neuralnet_cv <- readRDS(cv_file)
#> Warning: cannot open compressed file '', probable reason 'No such file or directory'
#> Error in gzfile(file, "rb"): cannot open the connection

# Plot parameter pair correlations
plot_cv_pair_correlation(abc_neuralnet_cv)
#> Error: object 'abc_neuralnet_cv' not found
```
