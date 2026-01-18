# Run a full simulation across multiple conditions in parallel

This function runs a complete simulation across multiple conditions
using parallel processing. It splits the conditions into chunks and
processes each chunk on separate cores. Each condition has multiple
trials and items. It uses the hierarchical structure: prior -\>
condition -\> trial -\> item. All parameters are taken from the
configuration object.

## Usage

``` r
run_simulation_parallel(config, output_dir)
```

## Arguments

- config:

  A eam_simulation_config object

- output_dir:

  The base output directory

## Value

No return value (results saved to disk)
