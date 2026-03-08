# eam (development version)

## New Features

- **ABI (Approximate Bayesian Inference) Module**: Complete neural network-based parameter estimation workflow
  - `abi_train()`: Train neural estimators using simulation-based inference
  - `abi_estimate()`: Obtain point estimates from trained models
  - `abi_assess()`: Assess trained estimator performance
  - `abi_sample_posterior()`: Sample from posterior distribution
  - Enhanced `build_abi_input()` with theta and Z outputs, test set support
  
- **Visualization**: New `plot_cv_recovery()` methods for ABI models (`eam_abi_assess` and `eam_abi_posterior_samples` classes)

- **Posterior Summarization**: `summarise_posterior_parameters()` for aggregating posterior samples

## Infrastructure

- Julia environment integration via `init_julia_env()` for neural network backend
- Add `tibble` dependency for improved output formatting

## Documentation

- Add inst/CITATION file with pre-print citation information
- Various documentation improvements and formatting fixes

# eam 1.1.0

- Add `build_abi_input` function to create input for ABI anlysis from EAM simulation output.
- Simulation allow more than 1024 data chunks/arrow partitions. Now, it depends on the hard limit of the arrow library and the file system.
- Fix `summarise_by()` to handle invalid column names returned by summary functions (e.g., quantile functions returning "90%", "95%"). Now uses `vctrs::vec_as_names()` for proper name repair.
- By convention of ABC, change the prior of `plot_posterior_parameters` to the hist graph.
- By convention of ABC, change the posterior of `plot_rt` to reflect the median RT within each condition.

## repo

- Add documentation with pkgdown.

# eam 1.0.1

- Initial release of this package.
