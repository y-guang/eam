# Run a single trial of the custom model placeholder

Run a single trial of the custom model placeholder

## Usage

``` r
run_trial_custom_model(
  trial_setting,
  item_formulas,
  n_items,
  max_reached,
  max_t,
  dt,
  noise_mechanism,
  noise_factory,
  trajectories = FALSE
)
```

## Arguments

- trial_setting:

  A list of named values representing the trial settings

- item_formulas:

  A list of formulas defining the item parameters

- n_items:

  The number of items to simulate

- max_reached:

  The threshold for evidence accumulation

- max_t:

  The maximum time to simulate

- dt:

  The step size for each increment

- noise_mechanism:

  The noise mechanism parameter, unused by this placeholder

- noise_factory:

  A noise factory parameter, unused by this placeholder

- trajectories:

  Whether to return full output including trajectories.

## Value

A list containing the simulation results
