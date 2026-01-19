# Changelog

## eam (development version)

- Simulation allow more than 1024 data chunks/arrow partitions. Now, it
  depends on the hard limit of the arrow library and the file system.
- Fix
  [`summarise_by()`](https://y-guang.github.io/eam/reference/summarise_by.md)
  to handle invalid column names returned by summary functions (e.g.,
  quantile functions returning “90%”, “95%”). Now uses
  [`vctrs::vec_as_names()`](https://vctrs.r-lib.org/reference/vec_as_names.html)
  for proper name repair.

### repo

- Add documentation with pkgdown.

## eam 1.0.1

CRAN release: 2026-01-17

- Initial release of this package.
