# Heuristic to calculate optimal chunk size for simulation configuration

Heuristic to calculate optimal chunk size for simulation configuration

## Usage

``` r
new_simulation_config.chunk_size.heuristic(
  n_conditions,
  n_trials_per_condition,
  n_items,
  parallel,
  n_cores
)
```

## Arguments

- n_conditions:

  Total number of conditions to simulate

- n_trials_per_condition:

  Number of trials per condition

- n_items:

  Number of items per trial

- parallel:

  Whether to run in parallel

- n_cores:

  Number of cores for parallel processing

## Value

Optimal number of conditions per chunk
