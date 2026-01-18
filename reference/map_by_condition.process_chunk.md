# Process a single chunk for map_by_condition

Process a single chunk for map_by_condition

## Usage

``` r
map_by_condition.process_chunk(open_dataset_fn, .f, ...)
```

## Arguments

- open_dataset_fn:

  Arrow dataset object or function that returns a dataset

- .f:

  Function to apply to each condition's data

- ...:

  Additional arguments passed to .f

## Value

Function that processes a chunk_idx
