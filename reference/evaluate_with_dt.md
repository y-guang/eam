# Evaluate a list of formulas sequentially with data

This function evaluates a list of formulas sequentially, allowing later
formulas to reference

## Usage

``` r
evaluate_with_dt(formulas, data = list(), n)
```

## Arguments

- formulas:

  A list of formulas to evaluate

- data:

  A list of named values to use as the initial environment

- n:

  The number of values to generate for each formula

## Value

A named list of evaluated values with length n
