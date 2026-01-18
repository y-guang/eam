# Pre-allocate data.table columns with appropriate data types

This function creates pre-allocated vectors for all columns in the final
data.table, determining data types from the first trial and condition.

## Usage

``` r
preallocate_columns(sim_results, trial_col_names, cond_param_names, total_rows)
```

## Arguments

- sim_results:

  The output from run_simulation(), a list of conditions

- trial_col_names:

  Character vector of trial column names

- cond_param_names:

  Character vector of condition parameter names

- total_rows:

  Integer, total number of rows to pre-allocate

## Value

Named list of pre-allocated vectors for each column
