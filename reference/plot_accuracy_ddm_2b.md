# Plot accuracy for DDM-2B model (internal)

Plot accuracy for DDM-2B model (internal)

## Usage

``` r
plot_accuracy_ddm_2b(
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

  Observed data frame

- x:

  Variable for x-axis

- facet_x:

  Variables for faceting columns

- facet_y:

  Variables for faceting rows

## Value

A ggplot2 object
