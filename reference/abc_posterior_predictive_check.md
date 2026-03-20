# ABC posterior predictive check

High-level convenience wrapper for posterior predictive checks from
[`abc_abc()`](https://y-guang.github.io/eam/reference/abc_abc.md)
outputs.

## Usage

``` r
abc_posterior_predictive_check(
  config,
  abc_result,
  observed_df,
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

- abc_result:

  Fitted object from
  [`abc_abc()`](https://y-guang.github.io/eam/reference/abc_abc.md).

- observed_df:

  Observed trial-level data frame.

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
intentionally specific to one input shape (an `abc` object). For step
checks, follow these functions:
[`abc_posterior_bootstrap()`](https://y-guang.github.io/eam/reference/abc_posterior_bootstrap.md),
[`update_config_from_posterior()`](https://y-guang.github.io/eam/reference/update_config_from_posterior.md),
and
[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md).
