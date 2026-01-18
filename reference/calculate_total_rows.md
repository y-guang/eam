# Calculate total number of rows needed for flattened data

This function counts the total number of items across all conditions and
trials to determine the size needed for pre-allocation.

## Usage

``` r
calculate_total_rows(sim_results, first_trial_col)
```

## Arguments

- sim_results:

  The output from run_simulation(), a list of conditions

- first_trial_col:

  Name of the first trial column to use for counting

## Value

Integer, total number of rows needed
