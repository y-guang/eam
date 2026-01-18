# Helper to resolved defined symbols in our formulas

This function evaluates an expression in a given environment.

## Usage

``` r
resolve_symbol(expr, env, n)
```

## Arguments

- expr:

  An expression to evaluate

- env:

  An environment to evaluate the expression in

- n:

  The number of values to generate if the expression is a distribution

## Value

The evaluated value as it is, no assumption on its type
