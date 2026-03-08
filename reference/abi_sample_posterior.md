# Sample from posterior distribution using trained neural estimator

A wrapper around
[`NeuralEstimators::sampleposterior()`](https://rdrr.io/pkg/NeuralEstimators/man/sampleposterior.html)
that automatically extracts the trained estimator from a trained
estimator object created by
[`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md) and
returns posterior samples in a 3D array format.

## Usage

``` r
abi_sample_posterior(trained_estimator, Z = NULL, N = 1000, ...)
```

## Arguments

- trained_estimator:

  A trained estimator object returned by
  [`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md).
  Must be of class `eam_abi_trained_estimator` and contain a
  `trained_estimator` element.

- Z:

  Data in a format amenable to the neural-network architecture of
  estimator. Can be a single data set or a list of data sets. If NULL
  (default), uses `Z_test` from the ABI input object.

- N:

  Integer; number of approximate posterior samples to draw (default:
  1000).

- ...:

  Additional keyword arguments passed to the Julia version of
  `sampleposterior()`, applicable when estimator is a
  likelihood-to-evidence-ratio estimator.

## Value

A tibble of class `eam_abi_posterior_samples` containing posterior
samples. Each row represents one posterior sample for one dataset.
Columns include `dataset_id` (integer dataset identifier) and one column
for each parameter.

## Details

This function extracts the trained neural posterior estimator from the
trained estimator object and uses it to sample from the approximate
posterior distribution given data Z. The samples are stacked using
Julia's [`stack()`](https://rdrr.io/r/utils/stack.html) function, then
converted to a tibble in R for easy manipulation and summarization.

## Note

This function initializes the global Julia environment on first call.

## Examples

``` r
if (FALSE) { # \dontrun{
# Train an estimator first
trained_estimator <- abi_train(
  estimator = estimator,
  abi_input = abi_input,
  epochs = 100
)

# Sample from posterior using test data (default)
posterior_samples <- abi_sample_posterior(
  trained_estimator = trained_estimator,
  N = 1000
)

# Sample from posterior for specific data
posterior_samples <- abi_sample_posterior(
  trained_estimator = trained_estimator,
  Z = abi_input$Z_test,
  N = 2000
)
} # }
```
