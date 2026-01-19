# Map a function by condition across simulation output chunks

This function processes simulation output by gathering all chunks,
iterating through them one by one, filtering and collecting data by
chunk, then applying a user-defined function by condition within each
chunk.

## Usage

``` r
map_by_condition(
  simulation_output,
  .f,
  ...,
  .combine = dplyr::bind_rows,
  .parallel = NULL,
  .n_cores = NULL,
  .progress = FALSE
)
```

## Arguments

- simulation_output:

  A eam_simulation_output object containing the dataset and
  configuration

- .f:

  A function to apply to each condition's data. The function should
  accept a data frame representing one condition's results

- ...:

  Additional arguments passed to the function .f

- .combine:

  Function to combine results (default: dplyr::bind_rows)

- .parallel:

  Logical or NULL.

- .n_cores:

  Integer. Number of CPU cores to use for parallel processing. If NULL,
  uses `detectCores() - 1`. Only used when `.parallel = TRUE`.

- .progress:

  Logical, whether to show a progress bar (default: FALSE)

## Value

A list containing the results of applying .f to each condition, with
names corresponding to condition indices

## Details

This function handles out-of-core computation automatically using Apache
Arrow, so you don't need to understand Arrow internals. It loads data
chunk by chunk to avoid memory issues with large simulations.

If you prefer to manually work with the raw Arrow dataset, you can
access it via `simulation_output$open_dataset()`, which returns an Arrow
Dataset object. You can then use `dplyr` verbs to filter and query
before calling
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to load data into memory.

## Examples

``` r
# Load simulation output
sim_output_path <- system.file(
  "extdata", "rdm_minimal", "simulation",
  package = "eam"
)
sim_output <- load_simulation_output(sim_output_path)

# Define a summary pipeline
summary_pipe <- summarise_by(
  .by = c("condition_idx"),
  rt_mean = mean(rt),
  rt_quantiles = quantile(rt, probs = c(0.1, 0.5, 0.9))
)

# Apply function to each condition
sim_sumstat <- map_by_condition(
  sim_output,
  .progress = FALSE,
  .parallel = FALSE,
  function(cond_df) {
    summary_pipe(cond_df)
  }
)
```
