# Initialize Julia Environment

Initializes the Julia environment for ABI methods. This function is
reentrant and will only perform initialization once per R session.

## Usage

``` r
init_julia_env()
```

## Value

Invisibly returns TRUE if initialization was performed, FALSE if already
initialized.

## Note

This function is not thread-safe. It assumes the caller is the main
thread. All callers should document the Julia initialization side effect
in their docstrings.
