# Build input for Approximate Bayesian Computation (ABC)

Prepares simulation output, summary statistics, and target data for ABC
analysis using the `abc` package. Extracts parameters and summary
statistics from simulation results and formats them into matrices
suitable for ABC parameter estimation.

## Usage

``` r
build_abc_input(simulation_output, simulation_summary, target_summary, param)
```

## Arguments

- simulation_output:

  A eam_simulation_output object containing that is from
  [`run_simulation`](https://y-guang.github.io/eam/reference/run_simulation.md)
  or
  [`load_simulation_output`](https://y-guang.github.io/eam/reference/load_simulation_output.md).

- simulation_summary:

  A data frame containing summary statistics for each simulated
  condition. Should have a 'condition_idx' column and be created by
  [`summarise_by`](https://y-guang.github.io/eam/reference/summarise_by.md).

- target_summary:

  A data frame containing target summary statistics to match against
  simulation results. Should have the same summary statistic columns as
  simulation_summary (excluding 'wider_by' columns).

- param:

  Character vector of parameter names to extract from simulation_output.
  These parameters will be used as the parameter space for ABC
  estimation.

## Value

A list with components suitable for
[`abc::abc`](https://rdrr.io/pkg/abc/man/abc.html)

## Details

This function provides a streamlined workflow for preparing ABC inputs,
but it requires that all components be constructed using this package's
functions. Specifically, `simulation_output` must be created by
[`run_simulation`](https://y-guang.github.io/eam/reference/run_simulation.md)
or
[`load_simulation_output`](https://y-guang.github.io/eam/reference/load_simulation_output.md),
and both `simulation_summary` and `target_summary` must be generated
using
[`summarise_by`](https://y-guang.github.io/eam/reference/summarise_by.md).
If your data originates from external sources or custom pipelines, you
should manually construct the ABC input list instead, ensuring proper
matrix formatting and column alignment as expected by
[`abc::abc`](https://rdrr.io/pkg/abc/man/abc.html).

## Required format for summary statistics

Both `simulation_summary` and `target_summary` must be created using
[`summarise_by`](https://y-guang.github.io/eam/reference/summarise_by.md).
This ensures consistent column naming and data structure required for
ABC analysis. See
[`summarise_by`](https://y-guang.github.io/eam/reference/summarise_by.md)
for details on generating properly formatted summaries, and
[`map_by_condition`](https://y-guang.github.io/eam/reference/map_by_condition.md)
for typical workflow examples. If you want more flexibility in summary
statistic calculation, you can manually construct the ABC input list. It
is not necessary to use this function if you are familiar with the `abc`
package.

## Examples

``` r
# \donttest{
# Load the example dataset
rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
sim_output <- load_simulation_output(file.path(rdm_minimal_example, "simulation"))
obs_df <- read.csv(file.path(rdm_minimal_example, "observation", "observation_data.csv"))

# Define summary statistics pipeline
summary_pipe <- summarise_by(
  .by = c("condition_idx"),
  rt_mean = mean(rt)
)

# Calculate summary statistics for simulation and observation
sim_summary <- map_by_condition(
  sim_output,
  .progress = FALSE,
  .parallel = FALSE,
  function(cond_df) {
    summary_pipe(cond_df)
  }
)
obs_summary <- summary_pipe(obs_df)

# Build ABC input
abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = sim_summary,
  target_summary = obs_summary,
  param = c("V_beta_1", "V_beta_group")
)

# Perform ABC parameter estimation using rejection method
abc_rejection_model <- abc::abc(
  target = abc_input$target,
  param = abc_input$param,
  sumstat = abc_input$sumstat,
  tol = 0.5,
  method = "rejection"
)
# }
```
