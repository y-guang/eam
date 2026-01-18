# Route model alias to backend and enrich configuration

This function uses a registry of backend detectors to determine which
backend implementation should handle the given configuration. Each
detector examines the config and returns a backend name if it can handle
it, or NULL otherwise. This design pattern (Chain of Responsibility)
makes it easy to add new backends without modifying this routing
function.

## Usage

``` r
route_model_to_backend(config)
```

## Arguments

- config:

  A list containing simulation configuration parameters

## Value

The modified config list with added 'backend' parameter
