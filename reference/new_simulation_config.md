# Create a new simulation configuration

This function creates a new eam simulation configuration object that
contains all parameters needed to run a simulation.

## Usage

``` r
new_simulation_config(
  prior_params = list(),
  prior_formulas = list(),
  between_trial_formulas = list(),
  item_formulas = list(),
  n_conditions_per_chunk = NULL,
  n_conditions,
  n_trials_per_condition,
  n_items,
  max_reached = n_items,
  max_t,
  dt = 0.001,
  noise_mechanism = "add",
  noise_factory = NULL,
  model = "ddm",
  parallel = FALSE,
  n_cores = NULL,
  rand_seed = NULL
)
```

## Arguments

- prior_params:

  A list or data frame of initial values for prior

- prior_formulas:

  A list of formulas defining prior distributions for condition-level
  parameters

- between_trial_formulas:

  A list of formulas defining between-trial parameters

- item_formulas:

  A list of formulas defining item-level parameters

- n_conditions_per_chunk:

  Number of conditions to process per chunk (optional, typically does
  not need to be set. It determine the storage and in-memory size of
  each chunk, if you find memory issues, try reducing this number)

- n_conditions:

  Total number of conditions to simulate

- n_trials_per_condition:

  Number of trials per condition

- n_items:

  Number of items per trial

- max_reached:

  Maximum number of items that can be recalled (default: n_items)

- max_t:

  Maximum simulation time

- dt:

  Time step size (default: 0.001)

- noise_mechanism:

  Noise mechanism ("add", "mult_evidence", or "mult_t", default: "add")

- noise_factory:

  Function that creates noise functions.

- model:

  Model name or backend names (e.g., "ddm", "rdm", "lca")

- parallel:

  Whether to run in parallel (default: FALSE)

- n_cores:

  Number of cores for parallel processing (default: NULL, auto-detect)

- rand_seed:

  Random seed for parallel processing (default: NULL)

## Value

An S3 object of class `eam_simulation_config` containing validated
simulation parameters. This object should be passed to
[`run_simulation`](https://y-guang.github.io/eam/reference/run_simulation.md)
to execute the simulation.

## Details

This function only creates the configuration object and does not run the
simulation. To actually execute the simulation, you must pass the
returned configuration object to
[`run_simulation`](https://y-guang.github.io/eam/reference/run_simulation.md).

**Supported Models:**

This package supports three evidence accumulation models. The
appropriate backend is automatically selected based on the `model`
parameter and the parameters defined in your formulas.

- **DDM (Drift Diffusion Model)**:

  Models evidence accumulation towards a single upper threshold. Items
  either reach the threshold and are recalled, or time out.

  *Required parameters* (must appear in `prior_formulas`,
  `between_trial_formulas`, or `item_formulas`):

  - `A` - Upper decision boundary/threshold

  - `V` - Drift rate (evidence accumulation rate)

  - `Z` - Starting point of evidence

  - `ndt` - Non-decision time

  Set `model = "ddm"`

- **RDM (Racing Diffusion Model)**:

  Models multiple racing evidence accumulators, each with upper and
  lower thresholds for binary decisions (correct/incorrect).

  *Required parameters*:

  - `A_upper` - Upper decision boundary (correct response)

  - `A_lower` - Lower decision boundary (incorrect response)

  - `V` - Drift rate

  - `Z` - Starting point of evidence

  - `ndt` - Non-decision time

  Set `model = "rdm"`. Note: If you set `model = "ddm"` but define
  `A_upper` instead of `A`, the model will automatically switch to RDM.

- **LCA (Leaky Competing Accumulator)**:

  Models competitive evidence accumulation with leakage and mutual
  inhibition between accumulators.

  *Required parameters*:

  - `A` - Decision threshold

  - `V` - Input strength/drift rate

  - `Z` - Starting point of evidence

  - `ndt` - Non-decision time

  - `beta` - Self-excitation/leak parameter

  - `k` - Lateral inhibition strength

  Set `model = "lca"`

- **LFM (Lévy Flight Model)**:

  Uses the same parameters as `DDM`. See `DDM` above.

  Set `model = "lfm"`

- **LBA (Linear Ballistic Accumulator)**:

  Uses the same parameters as `RDM`. See `RDM` above.

  Set `model = "lba"`

**Note:** All required parameters must be defined at least once across
`prior_params`, `prior_formulas`, `between_trial_formulas`, and
`item_formulas`.

**Parameter Hierarchy and Formula Evaluation:**

The simulation uses a hierarchical parameter system with sequential
formula evaluation, allowing later formulas to reference earlier ones:

1.  **prior_params** - Initial constant values available to all formulas

2.  **prior_formulas** - Evaluated once per condition, can reference
    `prior_params`. Use for condition-level parameters that vary across
    conditions.

3.  **between_trial_formulas** - Evaluated once per trial within each
    condition. Can reference both `prior_params` and variables from
    `prior_formulas`. Use for trial-level variability.

4.  **item_formulas** - Evaluated once per item within each trial. Can
    reference all previous parameters. Use for item-specific parameters.

**Using Distributions:**

You can use the `distributional` package to define random parameters.
For example:

- `A ~ distributional::dist_uniform(0.5, 2.0)` - Uniform distribution

- `V_condition ~ distributional::dist_normal(1.0, 0.2)` - Normal
  distribution

- `sigma ~ 0.5` - Constant value

- `V ~ distributional::dist_normal(V_condition, sigma)` - Reference
  earlier parameters

Each formula is evaluated sequentially, so you can build complex
parameter dependencies. For instance, you might define a base drift rate
`V` in `prior_formulas`, then add trial-level noise in
`between_trial_formulas`, and finally scale by item position in
`item_formulas`.

## Examples

``` r
# Define formulas for the simulation
prior_formulas <- list(
  V ~ distributional::dist_uniform(0.1, 1.0),
  ndt ~ 0.3,
  noise_coef ~ 1
)

between_trial_formulas <- list()

item_formulas <- list(
  A_upper ~ 1,
  A_lower ~ -1,
  V ~ V
)

# Define noise factory
noise_factory <- function(context) {
  noise_coef <- context$noise_coef
  function(n, dt) {
    noise_coef * rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

# Create configuration
config <- new_simulation_config(
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions = 10,
  n_trials_per_condition = 10,
  n_items = 5,
  max_reached = 5,
  max_t = 10,
  dt = 0.01,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "ddm",
  parallel = FALSE
)

# print the config
config
#> eam Simulation Configuration
#> =================================
#> Model: ddm 
#> Backend: ddm-2b 
#> Conditions: 10 
#> Trials per condition: 10 
#> Items per trial: 5 
#> Max reached: 5 
#> Max time: 10 
#> Time step: 0.01 
#> Noise mechanism: add 
#> Conditions per chunk: 10 
#> Parallel: FALSE 
#> 
#> Formulas:
#>   Prior formulas: 3 
#>   Between-trial formulas: 0 
#>   Item formulas: 3 

# Run simulation
sim_output <- run_simulation(config)
#> Error in accumulate_evidence_ddm_2b(item_params$A_upper, item_params$A_lower,     item_params$V, Z, item_params$ndt, max_t, dt, max_reached,     noise_mechanism, noise_fun): could not find function "accumulate_evidence_ddm_2b"
sim_output
#> Error: object 'sim_output' not found
```
