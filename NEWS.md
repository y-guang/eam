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
