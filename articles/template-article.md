# Template Article

## Introduction

It is recommended to use this template as a starting point for writing
articles.

## Section 1

First, let’s load the eam package.

``` r
library(eam)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

and config a basic EAM model.

``` r

# define the condition data generate logic
n_items <- 3
prior_params <- tibble(
  n_items = n_items
)

prior_formulas <- list(
  # V
  V_beta_1 ~ distributional::dist_lognormal(-1, 0.5),
  V_beta_group ~ distributional::dist_uniform(0.1, 0.3)
)

between_trial_formulas <- list(
  group ~ distributional::dist_binomial(1, 0.5)
)

item_formulas <- list(
  A_upper ~ 1,
  A_lower ~ -1,
  V ~ seq(1, n_items) * V_beta_1 + group * V_beta_group,
  ndt ~ 0
)

noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}
```

timestamp:

``` r
timestamp <- as.numeric(Sys.time())
timestamp
#> [1] 1768726088
```
