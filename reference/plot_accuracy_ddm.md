# Plot accuracy for DDM model (internal)

Calculates hit rate (proportion of trials with choice == 1) across all
possible trial combinations. For simulated data, expands grid based on
simulation config parameters and left joins with actual simulation
results. For observed data, assumes data is already in the correct
format.

## Usage

``` r
plot_accuracy_ddm(
  simulated_output,
  observed_df,
  x = "item_idx",
  facet_x = c(),
  facet_y = c()
)
```

## Arguments

- simulated_output:

  Simulation output object

- observed_df:

  Observed data frame (already expanded with all trial combinations)

- x:

  Variable for x-axis

- facet_x:

  Variables for faceting columns

- facet_y:

  Variables for faceting rows

## Value

A ggplot2 object
