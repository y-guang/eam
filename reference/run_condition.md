# Run a given condition with multiple trials

This function runs multiple trials for a given condition using the
specified

## Usage

``` r
run_condition(
  condition_setting,
  between_trial_formulas,
  item_formulas,
  n_trials,
  n_items,
  max_reached,
  max_t,
  dt,
  noise_mechanism,
  noise_factory,
  backend,
  trajectories = FALSE
)
```

## Arguments

- condition_setting:

  A list of named values representing the condition settings

- between_trial_formulas:

  A list of formulas defining the between-trial parameters

- item_formulas:

  A list of formulas defining the item parameters

- n_trials:

  The number of trials to simulate

- n_items:

  The number of items per trial

- max_reached:

  The threshold for evidence accumulation

- max_t:

  The maximum time to simulate

- dt:

  The step size for each increment

- noise_mechanism:

  The noise mechanism to use ("add" or "mult")

- noise_factory:

  A function that takes condition_setting and returns a noise function
  with signature function(n, dt)

- backend:

  The backend implementation to use ("ddm", "ddm-2b", or "lca-gi")

- trajectories:

  Whether to return full output including trajectories.

## Value

A list containing the simulation results and condition parameters
