# Fill pre-allocated data.table with simulation results

This function fills the pre-allocated data.table vectors with data from
simulation results, iterating through all conditions and trials.

## Usage

``` r
fill_data_table(
  sim_results,
  dt_lists,
  trial_col_names,
  cond_param_names,
  first_trial_col
)
```

## Arguments

- sim_results:

  The output from run_simulation(), a list of conditions

- dt_lists:

  Named list of pre-allocated vectors for each column

- trial_col_names:

  Character vector of trial column names

- cond_param_names:

  Character vector of condition parameter names

- first_trial_col:

  Name of the first trial column to use for item counting

## Value

Named list of filled vectors ready for data.table creation
