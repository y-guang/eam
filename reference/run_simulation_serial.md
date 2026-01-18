# Run a full simulation across multiple conditions (serial version)

This function runs a complete simulation across multiple conditions
serially, with each condition having multiple trials and items. It uses
the hierarchical structure: prior -\> condition -\> trial -\> item. All
parameters are taken from the configuration object.

## Usage

``` r
run_simulation_serial(config, output_dir)
```

## Arguments

- config:

  simulation config object

- output_dir:

  The base output directory

## Value

No return value (results saved to disk)
