# Plot accuracy comparison between posterior and observed data

Visualizes accuracy metrics comparing posterior simulation results with
observed data. Creates side-by-side bar plots for easy comparison across
conditions.

## Usage

``` r
plot_accuracy(
  simulated_output,
  observed_df,
  x = "item_idx",
  facet_x = c(),
  facet_y = c()
)
```

## Arguments

- simulated_output:

  Posterior simulation output from run_simulation()

- observed_df:

  Observed data frame

- x:

  Variable for x-axis (default: "item_idx")

- facet_x:

  Variables for faceting columns

- facet_y:

  Variables for faceting rows

## Value

A ggplot2 object

## Examples

``` r
# Load posterior simulation output and observed data
base_dir <- system.file("extdata", "rdm_minimal", package = "eam")
post_output <- load_simulation_output(file.path(base_dir, "abc", "posterior", "neuralnet"))
obs_df <- read.csv(file.path(base_dir, "observation", "observation_data.csv"))

# Plot accuracy comparison between posterior and observed data
# The plot shows side-by-side bars comparing hit rates or accuracy
plot_accuracy(
  post_output,
  obs_df,
  facet_x = c("group")
)
```
