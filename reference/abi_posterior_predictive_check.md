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

This wrapper is mainly a teaching tool. It provides a compact end-to-end
posterior predictive workflow for ABI, but it intentionally hides
several modeling choices behind a single helper call.

For more serious work, manual posterior predictive simulation is
preferred. The recommended workflow is to obtain parameter values
explicitly with
[`abi_estimate()`](https://y-guang.github.io/eam/reference/abi_estimate.md)
for point estimators or
[`abi_sample_posterior()`](https://y-guang.github.io/eam/reference/abi_sample_posterior.md)
for posterior estimators, inspect or summarise those values, rebuild a
simulation configuration explicitly with
[`new_simulation_config`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
so the parameter structure is fully under your control, run the
simulation with
[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md),
and then compare simulated and observed data using plotting or summary
functions.
[`update_config_from_posterior()`](https://y-guang.github.io/eam/reference/update_config_from_posterior.md)
can still be useful for quick checks, but rebuilding the config is the
safer option when you need to know exactly how inferred values are
mapped back into the model. Following the steps manually makes each
assumption visible, including which ABI output was used, how posterior
summaries were constructed, and how the posterior predictive data were
generated.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load an observed dataset and a trained ABI estimator prepared in your environment
observed_data <- sim_output$open_dataset() |>
  dplyr::filter(chunk_idx == 1, condition_idx == 1) |>
  dplyr::collect()

# Point-estimate workflow
abi_posterior_predictive_check(
  config = sim_config,
  trained_estimator = trained_point_estimator,
  estimator_type = "point",
  observed_df = observed_data,
  Z = abi_input$Z_test[[1]],
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c("ndt_beta_0"),
  accuracy_facet_y = c()
)

# Posterior-sampling workflow
abi_posterior_predictive_check(
  config = sim_config,
  trained_estimator = trained_posterior_estimator,
  estimator_type = "posterior",
  observed_df = observed_data,
  Z = abi_input$Z_test,
  posterior_dataset_id = 1,
  posterior_n_samples = 1000,
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c("ndt_beta_0"),
  accuracy_facet_y = c()
)
} # }
```
