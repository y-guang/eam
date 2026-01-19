# ABC model comparison wrapper

Wrapper function for [`postpr`](https://rdrr.io/pkg/abc/man/postpr.html)
to facilitate model comparison. This function simplifies the process of
comparing multiple models using ABC by automatically stacking summary
statistics and creating model indices.

## Usage

``` r
abc_postpr(sumstats = list(), target, ...)
```

## Arguments

- sumstats:

  A named list of summary statistics matrices from different models.
  Each element should be a matrix or data frame with the same columns.

- target:

  Target summary statistics from observed data (vector or matrix)

- ...:

  Additional arguments passed to
  [`postpr`](https://rdrr.io/pkg/abc/man/postpr.html)

## Value

An object of class "postpr" from
[`postpr`](https://rdrr.io/pkg/abc/man/postpr.html)

## Examples

``` r
# Load pre-computed ABC input for model comparison
# This example compares the same model to itself for demonstration
rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
abc_input <- readRDS(file.path(rdm_minimal_example, "abc", "abc_input.rds"))

# Compare two models using their summary statistics
# In practice, create different abc_input objects for different models:
# abc_input_1 <- build_abc_input(..., simulation_summary = sim_summary_1, ...)
# abc_input_2 <- build_abc_input(..., simulation_summary = sim_summary_2, ...)
postpr_result <- abc_postpr(
  sumstats = list(model1 = abc_input$sumstat, model2 = abc_input$sumstat),
  target = abc_input$target,
  tol = 0.5,
  method = "rejection"
)

# View model comparison results
summary(postpr_result)
#> Call: 
#> abc::postpr(target = target, index = index, sumstat = sumstat, 
#>     tol = 0.5, method = "rejection")
#> Data:
#>  postpr.out$values (500 posterior samples)
#> Models a priori:
#>  model1, model2
#> Models a posteriori:
#>  model1, model2
#> 
#> Proportion of accepted simulations (rejection):
#> model1 model2 
#>    0.5    0.5 
#> 
#> Bayes factors:
#>        model1 model2
#> model1      1      1
#> model2      1      1
#> 
#> 
```
