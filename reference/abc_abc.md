# Approximate Bayesian Computation wrapper

Wrapper around [`abc`](https://rdrr.io/pkg/abc/man/abc.html) to perform
ABC inference. This function provides a consistent interface within the
eam package and encapsulates the dependency on the abc package.

## Usage

``` r
abc_abc(abc_input, tol, method, transf = "none", ...)
```

## Arguments

- abc_input:

  A list with components `target`, `param`, and `sumstat` (typically
  produced by
  [`build_abc_input`](https://y-guang.github.io/eam/reference/build_abc_input.md))

- tol:

  Tolerance level (0 to 1) for ABC acceptance

- method:

  ABC method: "rejection", "loclinear", "neuralnet"

- transf:

  Transformations to apply to parameters: "none" (default), "log", or
  "logit"

- ...:

  Additional arguments passed to
  [`abc`](https://rdrr.io/pkg/abc/man/abc.html)

## Value

An object of class `abc` from
[`abc`](https://rdrr.io/pkg/abc/man/abc.html)

## Details

This is a thin wrapper around the
[`abc::abc()`](https://rdrr.io/pkg/abc/man/abc.html) function. Users
should refer to the abc package documentation for detailed parameter
descriptions and options.

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

# Build ABC input
abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = sim_summary,
  target_summary = obs_summary,
  param = c("V_beta_1", "V_beta_group")
)

# Fit an ABC model
abc_rejection_model <- abc_abc(
  abc_input = abc_input,
  tol = 0.5,
  method = "rejection"
)
# }
```
