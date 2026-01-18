# Template Article

## Introduction

It is recommended to use this template as a starting point for writing
articles.

## Section 1

First, let’s load the eam package.

``` r
library(eam)
library(dplyr)
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
#> [1] 1768731355
```

plot a simple figure:

``` r
x <- rnorm(100)
y <- 0.6 * x + rnorm(10, sd = 0.7)

plot(
  x, y,
  pch = 19,
  xlab = "x",
  ylab = "y",
  main = "Test Scatter Plot"
)

# Optional: add a fitted line
abline(lm(y ~ x), lwd = 2)
```

![plot of chunk unnamed-chunk-5](template-article/unnamed-chunk-5-1.svg)

plot of chunk unnamed-chunk-5

you should use

``` r
old <- getwd()
setwd("vignettes")

knitr::knit(
  "template-article.Rmd.orig",
  output = "template-article.Rmd"
)

setwd(old)
```

to generate the final Rmd file.

Then, run
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
to build the site locally.
