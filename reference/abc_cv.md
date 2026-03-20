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
