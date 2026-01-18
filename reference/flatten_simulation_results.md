# Convert simulation results to a tidy data.table

This function takes the nested list output from run_simulation() and
converts it into a tidy data.table where each row represents one item
response. The function pre-allocates the data.table to the exact size
needed and then fills it efficiently. Column names are dynamically
determined from the first trial result, excluding any .item_params
verbose output.

## Usage

``` r
flatten_simulation_results(sim_results)
```

## Arguments

- sim_results:

  The output from run_simulation(), a list of conditions

## Value

A data.table with columns: condition_idx, trial_idx, rank_idx, all
columns from trial results (excluding .item_params), and all variables
from cond_params
