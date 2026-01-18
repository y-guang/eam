# ABC with resampling

Performs ABC inference with resampling to assess stability and
uncertainty. Each iteration draws a random sample from the simulation
pool and runs ABC, producing multiple posterior estimates for
comparison.

## Usage

``` r
abc_resample(
  target,
  param,
  sumstat,
  n_iterations,
  n_samples,
  replace = FALSE,
  ...
)
```

## Arguments

- target:

  Target summary statistics from observed data

- param:

  Parameter values matrix or data frame

- sumstat:

  Summary statistics matrix or data frame

- n_iterations:

  Number of resample iterations

- n_samples:

  Number of samples to draw in each iteration

- replace:

  Logical, whether to sample with replacement (default FALSE)

- ...:

  Additional arguments passed to abc::abc

## Value

A list of length `n_iterations`, where each element is an object of
class `abc` returned by [`abc`](https://rdrr.io/pkg/abc/man/abc.html).
Each list element contains the ABC posterior for one bootstrap
iteration, allowing assessment of stability and uncertainty in parameter
estimates.

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
  n_iterations = 2,
  n_samples = 2,
  tol = 0.5,
  method = "rejection"
)
#> Error: object 'abc_input' not found

# check the abc results
str(results)
#> Error: object 'results' not found
```
