# Initialize simulation output directory structure

Creates and validates the output directory structure for a simulation.
This function ensures the directory is empty (or creates it), then
creates the required subdirectories based on simulation_output_fs_proto.

## Usage

``` r
init_simulation_output_dir(output_dir)
```

## Arguments

- output_dir:

  The base output directory path

## Value

The output_dir path (invisibly for chaining)
