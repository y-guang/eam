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

# Access the configuration
sim_output$simulation_config
#> eam Simulation Configuration
#> =================================
#> Model: rdm 
#> Backend: ddm-2b 
#> Conditions: 500 
#> Trials per condition: 100 
#> Items per trial: 3 
#> Max reached: 3 
#> Max time: 10 
#> Time step: 0.001 
#> Noise mechanism: add 
#> Conditions per chunk: 500 
#> Parallel: FALSE 
#> 
#> Formulas:
#>   Prior formulas: 2 
#>   Between-trial formulas: 1 
#>   Item formulas: 4 

# Access the dataset (check arrow documentation for working with the dataset)
dataset <- sim_output$open_dataset()
```
