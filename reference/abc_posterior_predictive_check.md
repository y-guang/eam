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

This wrapper is mainly a teaching tool. It provides a compact end-to-end
posterior predictive workflow, but it intentionally hides several
modeling choices by collapsing the posterior to a single summary and
then simulating from that reduced representation.

For more serious work, manual posterior predictive simulation is
preferred. The recommended workflow is to draw posterior parameter
values explicitly with
[`abc_posterior_bootstrap()`](https://y-guang.github.io/eam/reference/abc_posterior_bootstrap.md),
inspect or modify those draws as needed, rebuild a simulation
configuration explicitly with
[`new_simulation_config`](https://y-guang.github.io/eam/reference/new_simulation_config.md)
so the parameter structure is fully under your control, run the
simulation with
[`run_simulation()`](https://y-guang.github.io/eam/reference/run_simulation.md),
and then compare the simulated output with the observed data using
plotting or summary functions.
[`update_config_from_posterior()`](https://y-guang.github.io/eam/reference/update_config_from_posterior.md)
can still be useful for quick checks, but rebuilding the config is the
safer option when you need to know exactly how posterior values are
mapped back into the model. Following the steps manually makes each
assumption visible, including which posterior draw was used, how
parameter values entered the simulation config, and how the posterior
predictive data were generated.

## Examples

``` r
# \donttest{
# Load example simulation config, fitted ABC model, and observed data
base_dir <- system.file("extdata", "rdm_minimal", package = "eam")
sim_output <- load_simulation_output(file.path(base_dir, "simulation"))
abc_model <- readRDS(file.path(base_dir, "abc", "abc_neuralnet_model.rds"))
obs_df <- read.csv(file.path(base_dir, "observation", "observation_data.csv"))

# Run a high-level posterior predictive check
abc_posterior_predictive_check(
  config = sim_output$simulation_config,
  abc_result = abc_model,
  observed_df = obs_df,
  n_conditions = 1,
  n_trials_per_condition = 500,
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c("group"),
  accuracy_facet_y = c()
)
#> Error in accumulate_evidence_ddm_2b(item_params$A_upper, item_params$A_lower,     item_params$V, Z, item_params$ndt, max_t, dt, max_reached,     noise_mechanism, noise_fun): could not find function "accumulate_evidence_ddm_2b"
# }
```
