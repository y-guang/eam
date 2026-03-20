# Update a simulation config with posterior parameter values

Applies one posterior draw to an existing simulation configuration. For
each name in `posterior_params`: any matching entry in `prior_params` is
removed, any matching formula in `prior_formulas` is dropped, and the
posterior value is appended to `prior_params` as a fixed constant.

## Usage

``` r
update_config_from_posterior(
  config,
  posterior_params,
  n_conditions_per_chunk = NULL,
  n_conditions = config$n_conditions,
  n_trials_per_condition = config$n_trials_per_condition,
  n_items = config$n_items
)
```

## Arguments

- config:

  An `eam_simulation_config` object.

- posterior_params:

  A named list or data frame of posterior parameter values representing
  exactly one posterior draw.

- n_conditions_per_chunk:

  Number of conditions per processing chunk. `NULL` (default) recomputes
  the value via the internal heuristic.

- n_conditions:

  Total number of conditions to simulate. Defaults to the value already
  stored in `config`.

- n_trials_per_condition:

  Number of trials per condition. Defaults to the value already stored
  in `config`.

- n_items:

  Number of items per trial. Defaults to the value already stored in
  `config`.

## Value

A modified `eam_simulation_config` with updated `prior_params`, pruned
`prior_formulas`, and the four simulation-dimension fields.

## Note

This helper is intentionally conservative and mainly for teaching,
demonstrations, and quick posterior predictive checks. It freezes
selected top-level parameters to fixed posterior values for convenience,
but it does not reconstruct or reinterpret the full dependency structure
of the simulation specification. If `config$prior_params` is a data
frame with multiple rows, the single posterior draw is broadcast across
those rows when inserted.

It does not re-route backend selection and does not create a new model.
Parameters that appear on the left-hand side of `between_trial_formulas`
or `item_formulas` cannot be replaced automatically. If you need full
control and clarity over internal parameter structure, rebuild the
configuration manually using
[`new_simulation_config`](https://y-guang.github.io/eam/reference/new_simulation_config.md).
