# ABI posterior predictive check

High-level convenience wrapper for posterior predictive checks from
ABI-trained estimators.

## Usage

``` r
abi_posterior_predictive_check(
  config,
  trained_estimator,
  estimator_type = c("point", "posterior"),
  observed_df,
  Z = NULL,
  posterior_dataset_id = 1,
  posterior_n_samples = 1000,
  n_conditions = 1,
  n_trials_per_condition = 500,
  n_items = config$n_items,
  n_conditions_per_chunk = NULL,
  output_dir = NULL,
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c(),
  accuracy_facet_y = c()
)
```

## Arguments

- config:

  Simulation configuration object.

- trained_estimator:

  Trained ABI estimator from
  [`abi_train()`](https://y-guang.github.io/eam/reference/abi_train.md).

- estimator_type:

  Character string: `"point"` or `"posterior"`.

- observed_df:

  Observed trial-level data frame.

- Z:

  Input data for ABI estimation/sampling. If `NULL`, uses `Z_test`.

- posterior_dataset_id:

  Dataset id used when `estimator_type = "posterior"`.

- posterior_n_samples:

  Number of samples when `estimator_type = "posterior"`.

- n_conditions:

  Number of posterior predictive conditions.

- n_trials_per_condition:

  Number of trials per condition.

- n_items:

  Number of items per trial.

- n_conditions_per_chunk:

  Number of conditions per processing chunk.

- output_dir:

  Optional output directory for simulation files.

- rt_facet_x:

  Facet columns for
  [`plot_rt()`](https://y-guang.github.io/eam/reference/plot_rt.md) x
  facets.

- rt_facet_y:

  Facet columns for
  [`plot_rt()`](https://y-guang.github.io/eam/reference/plot_rt.md) y
  facets.

- accuracy_x:

  Grouping variable for
  [`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  x-axis.

- accuracy_facet_x:

  Facet columns for
  [`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  x facets.

- accuracy_facet_y:

  Facet columns for
  [`plot_accuracy()`](https://y-guang.github.io/eam/reference/plot_accuracy.md)
  y facets.

## Value

`invisible(NULL)`. This function is used for plotting side effects only
and prints RT and accuracy plots directly.

## Details

This function is for teaching and quick demonstrations. It is
intentionally specific to one estimator workflow at a time, selected by
`estimator_type`. For step checks, follow these functions:
[`abi_estimate()`](https://y-guang.github.io/eam/reference/abi_estimate.md)
or
[`abi_sample_posterior()`](https://y-guang.github.io/eam/reference/abi_sample_posterior.md),
then
[`update_config_from_posterior()`](https://y-guang.github.io/eam/reference/update_config_from_posterior.md),
and
[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md).
