# Bootstrap resample ABC posterior samples

Bootstrap resample ABC posterior samples

## Usage

``` r
abc_posterior_bootstrap(abc_result, n_samples, replace = TRUE)
```

## Arguments

- abc_result:

  An abc object from [`abc`](https://rdrr.io/pkg/abc/man/abc.html)

- n_samples:

  Number of bootstrap samples to draw (default 1000)

- replace:

  Logical, whether to sample with replacement (default TRUE)

## Value

Data frame of bootstrapped parameter values

## Examples

``` r
# Load an example abc output, you should generate it by applying ABC to your data
# check abc::abc for details on fitting ABC models
rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
abc_model <- readRDS(file.path(rdm_minimal_example, "abc", "abc_neuralnet_model.rds"))

# Bootstrap resample posterior parameters
posterior_params <- abc_posterior_bootstrap(
  abc_model,
  n_samples = 100
)

# View the first few rows of the bootstrapped posterior parameters
head(posterior_params)
#>         V_beta_1 V_beta_group
#> X232   0.2280897    0.1869761
#> X61    0.2587934    0.1670919
#> X150   0.2258720    0.1938078
#> X318   0.2608088    0.1624729
#> X318.1 0.2608088    0.1624729
#> X51    0.2649904    0.1941630
```
