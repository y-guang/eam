# Extract posterior medians from abc_resample output

Internal helper to compute parameter medians across abc_resample
iterations.

## Usage

``` r
extract_resample_medians(resample_results)
```

## Arguments

- resample_results:

  List of abc results from abc_resample

## Value

Matrix where each row is an iteration and each column is parameter
median
