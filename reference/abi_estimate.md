# Estimate parameters using trained neural estimator

A wrapper around
[`NeuralEstimators::estimate()`](https://rdrr.io/pkg/NeuralEstimators/man/estimate.html)
that automatically extracts the trained estimator from a trained
estimator object created by
[`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md).

## Usage

``` r
abi_estimate(trained_estimator, Z, X = NULL, batchsize = 32, use_gpu = TRUE)
```

## Arguments

- trained_estimator:

  A trained estimator object returned by
  [`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md).
  Must be of class `eam_abi_trained_estimator` and contain a
  `trained_estimator` element.

- Z:

  Data in a format amenable to the neural-network architecture of
  estimator. Can be a single data set or a list of data sets.

- X:

  Additional inputs to the neural network (default: NULL). If provided,
  the call will be of the form `estimator((Z, X))`.

- batchsize:

  Integer; the batch size for applying estimator to Z (default: 32).
  Batching occurs only if Z is a list, indicating multiple data sets.

- use_gpu:

  Logical; whether to use the GPU if available (default: TRUE).

## Value

A matrix of outputs resulting from applying the trained estimator to Z
(and possibly X).

## Details

This function extracts the trained neural estimator from the trained
estimator object and applies it to the provided data Z. The data Z
should be in the same format as the summary statistics used during
training (e.g., `Z_train`, `Z_val`, or `Z_test` from the ABI input).

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

# Estimate parameters for test data
point_est <- abi_estimate(
  trained_estimator = trained_estimator,
  Z = abi_input$Z_test[[1]]
)

# Estimate for multiple data sets
estimates <- abi_estimate(
  trained_estimator = trained_estimator,
  Z = abi_input$Z_test,
  batchsize = 16
)
} # }
```
