# Changelog

## eam 1.2.1

### Maintenance

- Move `pbapply` and `abc` from `Suggests` to `Imports` so they are
  installed with the package, which improves library installation
  experience and reduces confusion.

## eam 1.2.0

CRAN release: 2026-03-29

### New Features

- **ABI (Approximate Bayesian Inference) Module**: Complete neural
  network-based parameter estimation workflow

  - [`abi_train()`](https://y-guang.github.io/eam/reference/abi_train.md):
    Train neural estimators using simulation-based inference
  - [`abi_estimate()`](https://y-guang.github.io/eam/reference/abi_estimate.md):
    Obtain point estimates from trained models
  - [`abi_assess()`](https://y-guang.github.io/eam/reference/abi_assess.md):
    Assess trained estimator performance
  - [`abi_sample_posterior()`](https://y-guang.github.io/eam/reference/abi_sample_posterior.md):
    Sample from posterior distribution
  - Enhanced
    [`build_abi_input()`](https://y-guang.github.io/eam/reference/build_abi_input.md)
    with theta and Z outputs, test set support

- **ABC helpers**: Add
  [`abc_abc()`](https://y-guang.github.io/eam/reference/abc_abc.md) and
  [`abc_cv()`](https://y-guang.github.io/eam/reference/abc_cv.md)
  wrappers for ABC fitting and cross-validation

- **Posterior predictive workflows**: Add
  [`abc_posterior_predictive_check()`](https://y-guang.github.io/eam/reference/abc_posterior_predictive_check.md),
  [`abi_posterior_predictive_check()`](https://y-guang.github.io/eam/reference/abi_posterior_predictive_check.md),
  and
  [`update_config_from_posterior()`](https://y-guang.github.io/eam/reference/update_config_from_posterior.md)
  for teaching-oriented posterior simulation workflows

- **Visualization**:

  - New
    [`plot_cv_recovery()`](https://y-guang.github.io/eam/reference/plot_cv_recovery.md)
    methods for ABI models (`eam_abi_assess` and
    `eam_abi_posterior_samples` classes)
  - Update posterior RT and accuracy plots to compare simulated and
    observed data more directly
  - [`plot_rt()`](https://y-guang.github.io/eam/reference/plot_rt.md)
    now displays simulated RTs as densities and observed RTs as
    histograms

- **Posterior summarization**:
  [`summarise_posterior_parameters()`](https://y-guang.github.io/eam/reference/summarise_posterior_parameters.md)
  for aggregating posterior samples

### Infrastructure

- Julia environment integration via
  [`init_julia_env()`](https://y-guang.github.io/eam/reference/init_julia_env.md)
  for neural network backend
- Add bundled Julia project files under `inst/julia/env/` for ABI setup
- Add `tibble` dependency for improved output formatting
- Improve simulation routing, including LFM support and updated LBA
  routing

### Documentation

- Add inst/CITATION file with pre-print citation information
- Add and expand examples for ABC wrappers, posterior predictive
  helpers, and simulation-config updates
- Add ABI and ABC demos and refresh tutorial materials
- Various documentation improvements and formatting fixes

## eam 1.1.0

CRAN release: 2026-02-09

- Add `build_abi_input` function to create input for ABI anlysis from
  EAM simulation output.
- Simulation allow more than 1024 data chunks/arrow partitions. Now, it
  depends on the hard limit of the arrow library and the file system.
- Fix
  [`summarise_by()`](https://y-guang.github.io/eam/reference/summarise_by.md)
  to handle invalid column names returned by summary functions (e.g.,
  quantile functions returning “90%”, “95%”). Now uses
  [`vctrs::vec_as_names()`](https://vctrs.r-lib.org/reference/vec_as_names.html)
  for proper name repair.
- By convention of ABC, change the prior of `plot_posterior_parameters`
  to the hist graph.
- By convention of ABC, change the posterior of `plot_rt` to reflect the
  median RT within each condition.

### repo

- Add documentation with pkgdown.

## eam 1.0.1

CRAN release: 2026-01-17

- Initial release of this package.
