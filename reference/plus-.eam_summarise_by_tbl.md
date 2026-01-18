# Join two eam_summarise_by_tbl objects

S3 method for the + operator to join two summary tables created by
`summarise_by`. Tables must have identical .wider_by attributes to be
joined.

## Usage

``` r
# S3 method for class 'eam_summarise_by_tbl'
e1 + e2
```

## Arguments

- e1:

  First eam_summarise_by_tbl object

- e2:

  Second eam_summarise_by_tbl object

## Value

A joined data frame with class "eam_summarise_by_tbl", preserving the
.wider_by attribute from the input tables
