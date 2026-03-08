# Assess neural estimator using trained estimator

A wrapper around
[`NeuralEstimators::assess()`](https://rdrr.io/pkg/NeuralEstimators/man/assess.html)
that automatically unpacks the trained estimator and ABI input from a
trained estimator object created by
[`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md).

## Usage

``` r
abi_assess(
  trained_estimator,
  estimator_name = NULL,
  use_gpu = TRUE,
  verbose = TRUE
)
```

## Arguments

- trained_estimator:

  A trained estimator object returned by
  [`abi_train`](https://y-guang.github.io/eam/reference/abi_train.md).
  Must be of class `eam_abi_trained_estimator` and contain
  `trained_estimator` and `abi_input` elements.

- estimator_name:

  Character string; optional name for the estimator (default: NULL).

- use_gpu:

  Logical; whether to use GPU for assessment (default: TRUE).

- verbose:

  Logical; whether to print progress information (default: TRUE).

## Value

A list with class `eam_abi_assess` containing:

- estimates:

  Data frame with columns: m, k, j, estimator, parameter, estimate,
  truth

- runtimes:

  Data frame with runtime information

## Details

This function extracts the trained estimator and ABI input from the
trained estimator object, then extracts test parameters and summary
statistics from the ABI input, along with parameter names (`theta`), and
passes them to
[`NeuralEstimators::assess()`](https://rdrr.io/pkg/NeuralEstimators/man/assess.html).
The test set (`theta_test` and `Z_test`) is used for assessment.

The returned object has class `eam_abi_assess`, which enables the use of
S3 methods like
[`plot_cv_recovery`](https://y-guang.github.io/eam/reference/plot_cv_recovery.md)
for visualization.

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

# Assess the trained estimator
assessment <- abi_assess(
  trained_estimator = trained_estimator,
  estimator_name = "MyEstimator",
  use_gpu = TRUE,
  verbose = TRUE
)

# View the assessment results
str(assessment)

# Plot parameter recovery
plot_cv_recovery(assessment)
} # }
```
