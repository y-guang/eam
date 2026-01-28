# Extract and format summary statistics for ABI

Extract and format summary statistics for ABI

## Usage

``` r
build_abi_input.Z(output, Z, rank_levels, select_idx, n_trials_per_condition)
```

## Arguments

- output:

  Arrow dataset of simulation output

- Z:

  Character vector of summary statistic column names

- rank_levels:

  Numeric vector of rank indices to include

- select_idx:

  Vector of condition indices to extract

- n_trials_per_condition:

  Number of trials per condition

## Value

List of matrices, one per condition (ranks\*Z rows × trials columns)
