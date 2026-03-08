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

# check the abc results
str(results)
#> List of 2
#>  $ :List of 12
#>   ..$ unadj.values: Named num [1:2] 0.45 0.277
#>   .. ..- attr(*, "names")= chr [1:2] "V_beta_1" "V_beta_group"
#>   ..$ ss          : Named num [1:36] 0.794 0.239 0.408 0.613 0.9 ...
#>   .. ..- attr(*, "names")= chr [1:36] "rt_mean" "rt_quantiles_10%" "rt_quantiles_30%" "rt_quantiles_50%" ...
#>   ..$ dist        : Named num [1:2] 17.2 22.3
#>   .. ..- attr(*, "names")= chr [1:2] "466" "288"
#>   ..$ call        : language abc::abc(target = target, param = param_boot, sumstat = sumstat_boot, tol = 0.5,      method = "rejection")
#>   ..$ na.action   : logi [1:2] TRUE TRUE
#>   ..$ region      : Named logi [1:2] TRUE FALSE
#>   .. ..- attr(*, "names")= chr [1:2] "466" "288"
#>   ..$ transf      : chr [1:2] "none" "none"
#>   ..$ logit.bounds: num [1:2] 0 0
#>   ..$ method      : chr "rejection"
#>   ..$ numparam    : int 2
#>   ..$ numstat     : int 36
#>   ..$ names       :List of 2
#>   .. ..$ parameter.names : chr [1:2] "V_beta_1" "V_beta_group"
#>   .. ..$ statistics.names: chr [1:36] "rt_mean" "rt_quantiles_10%" "rt_quantiles_30%" "rt_quantiles_50%" ...
#>   ..- attr(*, "class")= chr "abc"
#>  $ :List of 12
#>   ..$ unadj.values: Named num [1:2] 0.154 0.244
#>   .. ..- attr(*, "names")= chr [1:2] "V_beta_1" "V_beta_group"
#>   ..$ ss          : Named num [1:36] 0.977 0.264 0.477 0.823 1.143 ...
#>   .. ..- attr(*, "names")= chr [1:36] "rt_mean" "rt_quantiles_10%" "rt_quantiles_30%" "rt_quantiles_50%" ...
#>   ..$ dist        : Named num [1:2] 8.03 1.69
#>   .. ..- attr(*, "names")= chr [1:2] "197" "311"
#>   ..$ call        : language abc::abc(target = target, param = param_boot, sumstat = sumstat_boot, tol = 0.5,      method = "rejection")
#>   ..$ na.action   : logi [1:2] TRUE TRUE
#>   ..$ region      : Named logi [1:2] FALSE TRUE
#>   .. ..- attr(*, "names")= chr [1:2] "197" "311"
#>   ..$ transf      : chr [1:2] "none" "none"
#>   ..$ logit.bounds: num [1:2] 0 0
#>   ..$ method      : chr "rejection"
#>   ..$ numparam    : int 2
#>   ..$ numstat     : int 36
#>   ..$ names       :List of 2
#>   .. ..$ parameter.names : chr [1:2] "V_beta_1" "V_beta_group"
#>   .. ..$ statistics.names: chr [1:36] "rt_mean" "rt_quantiles_10%" "rt_quantiles_30%" "rt_quantiles_50%" ...
#>   ..- attr(*, "class")= chr "abc"
```
