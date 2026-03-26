# Cross-validation for ABC model

Wrapper around [`cv4abc`](https://rdrr.io/pkg/abc/man/cv4abc.html) to
perform cross-validation of ABC results. This function provides a
consistent interface within the eam package and encapsulates the
dependency on the abc package.

## Usage

``` r
abc_cv(abc_input, abc_result, nval, tols, ...)
```

## Arguments

- abc_input:

  A list with components `param` and `sumstat` (typically produced by
  [`build_abc_input`](https://y-guang.github.io/eam/reference/build_abc_input.md))

- abc_result:

  Fitted ABC model from
  [`abc_abc`](https://y-guang.github.io/eam/reference/abc_abc.md).
  Parameters like `method`, `transf`, etc. are extracted from this
  object.

- nval:

  Number of cross-validation folds

- tols:

  Tolerance levels to test during cross-validation

- ...:

  Additional arguments passed to
  [`cv4abc`](https://rdrr.io/pkg/abc/man/cv4abc.html)

## Value

A cross-validation object from
[`cv4abc`](https://rdrr.io/pkg/abc/man/cv4abc.html)

## Details

This is a thin wrapper around the
[`abc::cv4abc()`](https://rdrr.io/pkg/abc/man/cv4abc.html) function.
When `abc_result` is provided, cv4abc extracts the method, transf, and
other settings from the fitted ABC object. Users should refer to the abc
package documentation for detailed parameter descriptions and options.

## Examples

``` r
# \donttest{
# Load example simulation output and observed data
rdm_minimal_example <- system.file("extdata", "rdm_minimal", package = "eam")
sim_output <- load_simulation_output(file.path(rdm_minimal_example, "simulation"))
obs_df <- read.csv(file.path(rdm_minimal_example, "observation", "observation_data.csv"))

# Define a summary-statistics pipeline
summary_pipe <- summarise_by(
  .by = c("condition_idx"),
  rt_mean = mean(rt)
)

# Summarise simulation output and observed data
sim_summary <- map_by_condition(
  sim_output,
  .progress = FALSE,
  .parallel = FALSE,
  function(cond_df) {
    summary_pipe(cond_df)
  }
)
obs_summary <- summary_pipe(obs_df)

# Build ABC input and fit an ABC model
abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = sim_summary,
  target_summary = obs_summary,
  param = c("V_beta_1", "V_beta_group")
)
abc_model <- abc_abc(
  abc_input = abc_input,
  tol = 0.5,
  method = "rejection"
)

# Run cross-validation for the fitted ABC model
abc_cv_result <- abc_cv(
  abc_input = abc_input,
  abc_result = abc_model,
  nval = 10,
  tols = c(0.1, 0.5)
)
# }
```
