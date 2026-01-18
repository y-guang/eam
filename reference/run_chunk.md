# Run a chunk of simulation conditions and save results to disk

This function processes a chunk of simulation conditions, applies the
flatten_simulation_results transformation, and saves the results to disk
using Arrow's write_dataset with partitioning by chunk_idx.

## Usage

``` r
run_chunk(config, output_dir, chunk_idx)
```

## Arguments

- config:

  A eam_simulation_config object containing all simulation parameters

- output_dir:

  The base output directory

- chunk_idx:

  The chunk index for partitioning (1-based)

## Value

Invisible NULL (results are saved to disk)
