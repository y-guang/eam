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
#> Warning: cannot open compressed file '/abc/abc_neuralnet_model.rds', probable reason 'No such file or directory'
#> Error in gzfile(file, "rb"): cannot open the connection

# Bootstrap resample posterior parameters
posterior_params <- abc_posterior_bootstrap(
  abc_model,
  n_samples = 100
)
#> Error: object 'abc_model' not found

# View the first few rows of the bootstrapped posterior parameters
head(posterior_params)
#> Error: object 'posterior_params' not found
```
