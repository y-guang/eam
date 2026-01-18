# Rebuild eam_simulation_output from an existing output directory

This function reconstructs a eam_simulation_output object from a
previously saved simulation output directory.

## Usage

``` r
load_simulation_output(output_dir)
```

## Arguments

- output_dir:

  The directory containing the simulation results and config

## Value

A eam_simulation_output object

## Examples

``` r
# Load simulation output from package data
sim_output_path <- system.file(
  "extdata", "rdm_minimal", "simulation",
  package = "eam"
)
sim_output <- load_simulation_output(sim_output_path)
#> Error in load_simulation_output(sim_output_path): Output directory does not exist: 

# Access the configuration
sim_output$simulation_config
#> Error: object 'sim_output' not found

# Access the dataset (check arrow documentation for working with the dataset)
dataset <- sim_output$open_dataset()
#> Error: object 'sim_output' not found
```
