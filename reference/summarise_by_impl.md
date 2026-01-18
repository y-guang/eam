# Internal function to perform the core summarise_by logic

Internal function to perform the core summarise_by logic

## Usage

``` r
summarise_by_impl(.data, dots, .by, .wider_by)
```

## Arguments

- .data:

  A data frame to summarise

- dots:

  Quosures containing the summary expressions

- .by:

  Character vector of column names to group by

- .wider_by:

  Character vector of column names to keep as identifying columns

## Value

A data frame with class "eam_summarise_by_tbl"
