# Train neural estimator using ABI input

A wrapper around
[`NeuralEstimators::train()`](https://rdrr.io/pkg/NeuralEstimators/man/train.html)
that automatically unpacks parameters and summary statistics from an ABI
input object created by
[`build_abi_input`](https://y-guang.github.io/eam/reference/build_abi_input.md).

## Usage

``` r
abi_train(
  estimator,
  abi_input,
  train_subset = "train",
  val_subset = "val",
  loss = "absolute-error",
  learning_rate = 1e-04,
  epochs = 100,
  batchsize = 32,
  savepath = NULL,
  stopping_epochs = 5,
  use_gpu = TRUE,
  verbose = TRUE,
  ...
)
```

## Arguments

- estimator:

  A neural estimator to train, or a character string of Julia code that
  evaluates to an estimator. See
  [`NeuralEstimators::train`](https://rdrr.io/pkg/NeuralEstimators/man/train.html)
  for details.

- abi_input:

  An ABI input object created by
  [`build_abi_input`](https://y-guang.github.io/eam/reference/build_abi_input.md).
  Must contain `theta_train`, `Z_train`, `theta_val`, and `Z_val`
  elements.

- train_subset:

  Character string specifying which subset to use for training: "train",
  "val", or "test" (default: "train").

- val_subset:

  Character string specifying which subset to use for validation:
  "train", "val", or "test" (default: "val").

- loss:

  Character string specifying the loss function: 'absolute-error' for
  mean-absolute-error loss or 'squared-error' for mean-squared-error
  loss (default: 'absolute-error'). Can also be a string of Julia code
  defining a custom loss function.

- learning_rate:

  Numeric; learning rate for the ADAM optimizer (default: 1e-4).

- epochs:

  Integer; number of training epochs (default: 100).

- batchsize:

  Integer; batch size for stochastic gradient descent (default: 32).

- savepath:

  Character string; path to save the trained estimator and training
  information. If NULL (default), nothing is saved.

- stopping_epochs:

  Integer; stop training if validation risk doesn't improve for this
  many epochs (default: 5).

- use_gpu:

  Logical; whether to use GPU if available (default: TRUE).

- verbose:

  Logical; whether to print training information (default: TRUE).

- ...:

  Additional arguments passed to
  [`NeuralEstimators::train()`](https://rdrr.io/pkg/NeuralEstimators/man/train.html).

## Value

A list with class `eam_abi_trained_estimator` containing:

- original_estimator:

  The initial estimator before training

- trained_estimator:

  The trained neural estimator

- abi_input:

  The ABI input object used for training

## Details

This function extracts training and validation parameters and summary
statistics from the ABI input object and passes them to
[`NeuralEstimators::train()`](https://rdrr.io/pkg/NeuralEstimators/man/train.html).
The training data (`theta_train` and `Z_train`) are used for updating
the estimator via stochastic gradient descent, while the validation data
(`theta_val` and `Z_val`) are used for monitoring performance and early
stopping.

If `savepath` is provided, the neural network parameters will be saved
as BSON files during training, along with loss values in
`loss_per_epoch.csv` and the best parameters in `best_network.bson`.

## Note

This function initializes the global Julia environment on first call.

## Examples

``` r
if (FALSE) { # \dontrun{
# Train a neural estimator with ABI input
trained_estimator <- abi_train(
  estimator = estimator,
  abi_input = abi_input,
  epochs = 100,
  learning_rate = 1e-4,
  batchsize = 32,
  use_gpu = TRUE
)

# Train with custom save path
trained_estimator <- abi_train(
  estimator = estimator,
  abi_input = abi_input,
  epochs = 200,
  savepath = "path/to/save"
)
} # }
```
