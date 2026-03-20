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

  ABC method: "rejection", "loclinear", "neuralnet", or "ridge"

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
