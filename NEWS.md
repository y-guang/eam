# eam (development version)

- Simulation allow more than 1024 data chunks/arrow partitions. Now, it depends on the hard limit of the arrow library and the file system.
- Fix `summarise_by()` to handle invalid column names returned by summary functions (e.g., quantile functions returning "90%", "95%"). Now uses `vctrs::vec_as_names()` for proper name repair.

## repo

- Add documentation with pkgdown.

# eam 1.0.1

- Initial release of this package.
