# Run a single trial of the DDM simulation

This function runs a single trial of the DDM simulation using the
provided item formulas and trial settings. It's a wrapper around the
core C++ function

## Usage

``` r
run_trial_ddm(
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

  The noise mechanism to use ("add" or "mult")

- noise_factory:

  A function that takes trial_setting and returns a noise function with
  signature function(n, dt)

- trajectories:

  Whether to return full output including trajectories.

## Value

A list containing the simulation results

## Note

After evaluation, parameters A, V, and ndt are expected to be numeric
vectors of length n_items. And they are matched by position. So, the
first element of A, V, and ndt corresponds to the first item, and so on.
