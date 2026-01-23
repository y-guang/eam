# Models in eam

This section introduces the setting for five representative models:
Diffusion decision model (DDM; Ratcliff, 1978), Leaky Competing
Accumulator (LCA; Usher & McClelland, 2001), Linear Ballistic
Accumulator (LBA; Brown & Heathcote, 2008), Racing Diffusion Model (RDM;
Tillman et al., 2020), Lévy Flight Model (LFM; Wieschen et al., 2020).
Meanwhile, we also provide a tutorial on how to extend them to
multi-response variants or interget covariates into the simualtion and
inference.

In practice, when fitting these models to real data, the
simulation-and-summary pipeline shown below can be combined directly
with the Section 1 workflow [Getting Started: A Minimal Working
Example](https://y-guang.github.io/eam/articles/10-minimal-working-example.md)
by replacing the simulations models and observed dataset.

The following sections will introduce each model in detail:

## Diffusion decision model

The diffusion decision model (DDM) is is a double-boundary
single-accumulator EAM with Gaussian noise. The moment-to-moment change
in accumulated evidence $x(t)$ is expressed as:
$$dx(t) = v \cdot dt + \omega \cdot dW_{t},$$$$dW_{t} \sim N(0,\, dt),$$
where the diffusion noise term $dW_{t}$ at each time step is drawn from
a Gaussian distribution with mean 0 and variance $dt$. The diffusion
scaling parameter $\omega$ is typically fixed at 1. The starting point
$z$ in the DDM is often expressed as a proportion of the decision
boundary $a$: $$z = \rho \cdot a,\qquad\rho \in \lbrack 0,\, 1\rbrack,$$
where $\rho$ denotes relative bias toward the upper boundary $a$. A
larger $\rho$ places the starting point closer to the upper boundary,
making it easier and faster for the process to reach it, increasing the
probability of a correct response.

The free parameters of the model thus include the drift rate $v$, the
decision boundary $a$, the starting point $z$ (or relative bias $\rho$),
and the non-decision time $t_{0}$.

Beyond these core parameters, the DDM also incorporates three sources of
between-trial variability: variability in drift rate ($s_{v}$), starting
point ($s_{z}$), and non-decision time ($s_{t0}$). These components are
optional, yet including them enables the model to better capture
empirical RT distributions, explain “fast errors”, and separate
within-trial noise from between-trial variability.

``` r
# Set the number of accumulators in the model
n_items <-1

prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_0 ~ distributional::dist_uniform(0.5, 3),
  S_V ~ distributional::dist_uniform(0, 1),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  S_ndt ~ distributional::dist_uniform(0, 1),
  # Relative starting point
  Z_0 ~ distributional::dist_uniform(-0.5, 0.5),
  S_Z ~ distributional::dist_uniform(0, 0.3)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Between trial variability in drift rate
  V_var ~ distributional::dist_normal(0, S_V),
  # Between trial variability in non-decision time
  ndt_var ~ distributional::dist_uniform(-S_ndt, S_ndt),
  # Between trial variability in starting point
  Z_var ~ distributional::dist_uniform(-S_Z, S_Z)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_0 + Z_var,
  # Decision boundary
  A_upper ~ A_0, # upper 
  A_lower ~ -A_0, # lower
  # Drift rate
  V ~ V_0 + V_var,
  # Non-decision time
  ndt ~ ndt_0 + ndt_var
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = n_items,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm-2b",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "choice"),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7 ,0.9))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Leaky competing accumulator

The leaky competing accumulator model is a single-boundary,
multi-accumulator evidence-accumulation model with Gaussian noise.
Beyond stochastic fluctuations, the evolution of evidence in each
accumulator is shaped by a leakage term $kx_{i}$ and a lateral
inhibition term $\beta\sum_{j \neq i}x_{j}$:
$$dx_{i}(t) = \left( v_{i} - kx_{i} - \beta\sum\limits_{j \neq i}x_{j} \right) \cdot dt + s \cdot dW_{t},$$$$dW_{t} \sim N(0,\, dt).$$

Here, $k$ is the leakage parameter that governs the rate at which
accumulated evidence decays over time, $x_{i}$ denotes the accumulated
evidence in accumulator $i$, $\beta$ controls the strength of lateral
inhibition exerted by competing accumulators, and $\sum_{j \neq i}x_{j}$
represents the total evidence of all competing alternatives.

The LCA adopts a single decision boundary $a$ shared across all
accumulators, and a response is triggered when the first accumulator
reaches that boundary. In a two-accumulator system, the parameters to be
estimated usually include the drift rates for each alternative $v_{i}$,
the leakage parameter $k$, the inhibition strength $\beta$, the decision
boundary $a$, and the non-decision time $t_{0}$.

``` r
# Set the number of accumulators in the model
n_items <-2

prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_acc1 ~ distributional::dist_uniform(0.5, 3),
  V_acc2 ~ distributional::dist_uniform(0.5, 3),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  # Leakage parameter
  k ~ distributional::dist_uniform(0, 0.5),
  # Inhibition strength
  beta ~ distributional::dist_uniform(0, 0.5)
)

# Specify the between-trial components
between_trial_formulas <- list(
)

# Specify the item-level parameters
item_formulas <- list(
  # Decision boundary
  A ~ A_0,
  # Drift rate
  V ~ c(V_acc1, V_acc2)
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = 1,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "lca",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output_1")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)
```

It is worth noting that, in the case of LCA, LBA and RDM, due to the
presence of two items and an upper boundary only, the choice variable
should be replaced with item_idx, when calculating the accuracy.

``` r
# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(item_idx == 1) / sum(!is.na(item_idx)),
  ) +
  summarise_by(
    .by = c("condition_idx", "item_idx"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7 ,0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Linear ballistic accumulator

The linear ballistic accumulator model is a single-boundary
multiple-accumulator EAM with non-decision noise. Without stochastic
fluctuations moment to moment, the accumulated evidence evolves as a
straight line with slope equal to the drift rate $v_{i}$, and the
response and RT is determined by the first accumulator to reach its
threshold: $$dx(t) = v_{i} \cdot dt.$$

To account for between-trial variability in observed response and RTs,
the LBA introduces two additional random components. First, on each
trial, each accumulator begins with a random starting point $z_{i}$
sampled from a uniform distribution $U(0,Z)$, capturing variability in
initial bias. Second, on each trial, the drift rate for each accumulator
is drawn from a Gaussian distribution with mean $V_{i}$ and variance
$\tau$, representing the variability in quality of evidence:
$$v_{i} \sim N\left( V_{i},\ \tau \right).$$

For model identifiability, $\tau$ is typically fixed as a constant, or
constraints are imposed on the mean drift rates (e.g.,
$V_{1} + V_{2} = 1$). The free parameters of the model thus include the
mean drift rate for each accumulator $V_{i}$, the decision boundary $a$,
the upper bound of starting point $Z$, and the non-decision time
$t_{0}$. This design gives the LBA greater flexibility in capturing
error RT distributions and allows straightforward extension to tasks
with more than two options by simply adding more accumulators.

``` r
# Set the number of accumulators in the model
n_items <-2

prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_mu_acc1 ~ distributional::dist_uniform(0.5, 3),
  V_mu_acc2 ~ distributional::dist_uniform(0.5, 3),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  # Upper limit of starting point
  Z_upper ~ distributional::dist_uniform(0, 0.5)
)

# Specify the between-trial components
between_trial_formulas <- list(
  V_acc1 ~ max(distributional::dist_normal(mean = V_mu_acc1, sd = 1), 1e-5),
  V_acc2 ~ max(distributional::dist_normal(mean = V_mu_acc2, sd = 1), 1e-5),
  Z_0   ~ distributional::dist_uniform(0, Z_upper)
)

# Specify the item-level parameters
item_formulas <- list(
  # Decision boundary
  A ~ A_0,
  # Drift rate
  V ~ c(V_acc1, V_acc2),
  # Starting point
  Z ~ Z_0
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    0*rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = 1,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output_1")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(item_idx == 1) / sum(!is.na(item_idx)),
  ) +
  summarise_by(
    .by = c("condition_idx", "item_idx"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7 ,0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Racing diffusion model

The racing diffusion model is a single-boundary, multiple-accumulator
EAM with Gaussian noise. The moment-to-moment change in accumulated
evidence, $x(t)$, follows the same stochastic updating rule as in the
DDM; the key difference lies in how incorrect responses are determined,
namely by allowing multiple accumulators to \`\`race’’ toward the upper
decision boundary, with the first to cross it dictating the response and
RT.

Due to concerns about parameter recovery, the RDM avoids estimating
between-trial variability in drift rates ($s_{v}$) while still allowing
starting points ($s_{z}$) to vary across trials to improve the fit to
empirical RT distributions.

``` r
# Set the number of accumulators in the model
n_items <-2

prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_acc1 ~ distributional::dist_uniform(0.5, 3),
  V_acc2 ~ distributional::dist_uniform(0.5, 3),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  # Relative starting point
  Z_upper ~ distributional::dist_uniform(0, 0.5)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Between trial variability in starting point
  Z_var ~ distributional::dist_uniform(0, Z_upper)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_var,
  # Decision boundary
  A ~ A_0, # upper 
  # Drift rate
  V ~ c(V_acc1, V_acc2),
  # Non-decision time
  ndt ~ ndt_0
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = 2,
  max_reached = 1,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(item_idx == 1) / sum(!is.na(item_idx)),
  ) +
  summarise_by(
    .by = c("condition_idx", "item_idx"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7 ,0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Lévy flight model

The Lévy flight model (LFM) extends the traditional DDM in a different
direction by replacing the Gaussian diffusion noise with a Lévy
$\alpha$-stable distribution, allowing occasional large evidence jumps
to capture heavy-tailed RT distributions. It is a double-boundary
single-accumulator EAM with Lévy $\alpha$-stable noise. The
moment-to-moment change in accumulated evidence $x(t)$ thus follows the
rules:
$$dx(t) = v \cdot dt + s \cdot dL_{\alpha}(t),$$$$dL_{\alpha}(t) \sim S_{\alpha}(\gamma,\ \varepsilon,\ \mu),$$
where $S_{\alpha}( \cdot )$ denotes a Lévy $\alpha$-stable distribution
parameterized by:

In the LFM, the stability parameter $\alpha$ is free to be estimated
from the data, whereas the skewness ($\gamma$), scale ($\varepsilon$),
and location ($\mu$) are fixed. Thus, the free parameters of the LFM
include the drift rate for a single accumulator $v$, the decision
boundary $a$, the starting point $z$, the non-decision time $t_{0}$, and
the stability parameter $\alpha$. The LFM allows between-trial
variability in drift rates ($s_{v}$), starting points ($s_{z}$), and
non-decision time ($s_{t0}$).

``` r
# Load the package for Lévy alpha-stable distribution
library(stabledist)

# Set the number of accumulators in the model
n_items <-1

prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_0 ~ distributional::dist_uniform(0.5, 3),
  S_V ~ distributional::dist_uniform(0, 1),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  S_ndt ~ distributional::dist_uniform(0, 1),
  # Relative starting point
  Z_0 ~ distributional::dist_uniform(-0.5, 0.5),
  S_Z ~ distributional::dist_uniform(0, 0.3),
  # Stability parameter
  alpha    ~ distributional::dist_uniform(1, 2)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Between trial variability in drift rate
  V_var ~ distributional::dist_normal(0, S_V),
  # Between trial variability in non-decision time
  ndt_var ~ distributional::dist_uniform(-S_ndt, S_ndt),
  # Between trial variability in starting point
  Z_var ~ distributional::dist_uniform(-S_Z, S_Z)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_0 + Z_var,
  # Decision boundary
  A_upper ~ A_0, # upper 
  A_lower ~ -A_0, # lower
  # Drift rate
  V ~ V_0 + V_var,
  # Non-decision time
  ndt ~ ndt_0 + ndt_var
)

# Specify the diffusion noise
noise_factory <- function(context) {
    alpha <- context$alpha
    function(n, dt) sqrt(dt)*rstable(n, alpha = alpha, beta = 0, gamma = 1/sqrt(2), delta = 0)
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = n_items,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm-2b",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "choice"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7 ,0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Multi-response EAM

To simulate a multi-response EAM, we introduced two additional
components: a position-dependent decision boundary function and an
item-dependent drift rate function.

First, the decision boundary was modeled as a linear increasing function
of output position $o$: $$a(o) = a_{0} + a_{1} \cdot o,$$ where $a_{0}$
represents the decision boundary for the first-retrieved item and
$a_{1} > 0$ captures the rate at which the boundary increases across
retrieval positions.

As the recall episode progresses, the criterion for terminating evidence
accumulation becomes more stringent. Such an increase may arise from
increased caution in memory retrieval. Importantly, because the boundary
is linked to output position rather than item index, items with lower
drift rates may reach the lower boundary by chance.

Second, drift rates were specified as a linear decreasing function of
item index $i$:

$$v(i) = v_{0} + v_{1} \cdot i,$$

where $v_{0}$ represents the drift rate for the first item and
$v_{1} < 0$ reflects the decline in evidence strength across positions.
This was intended to capture the reduction in available memory cues or
retrieval strength for later items, a pattern commonly observed in free
recall tasks.

The following example use DDM as a template and extend it to a
multi-response version:

``` r
# Set the number of accumulators in the model
n_items <-3

# Specify the prior distributions for free parameters
prior_formulas <- list(
  n_items ~ 3,
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  A_1 ~ distributional::dist_uniform(0, 1),
  # Drift rate
  V_0 ~ distributional::dist_uniform(0.5, 3),
  V_1 ~ distributional::dist_uniform(0, 0.3),
  S_V ~ distributional::dist_uniform(0, 1),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  S_ndt ~ distributional::dist_uniform(0, 1),
  # Relative starting point
  Z_0 ~ distributional::dist_uniform(-0.5, 0.5),
  S_Z ~ distributional::dist_uniform(0, 0.3)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Between trial variability in drift rate
  V_var ~ distributional::dist_normal(0, S_V),
  # Between trial variability in non-decision time
  ndt_var ~ distributional::dist_uniform(-S_ndt, S_ndt),
  # Between trial variability in starting point
  Z_var ~ distributional::dist_uniform(-S_Z, S_Z)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_0 + Z_var,
  # Decision boundary
  A_upper ~ (A_0 + seq(1, n_items) * A_1), # upper 
  A_lower ~ -(A_0 + seq(1, n_items) * A_1), # lower
  # Drift rate
  V ~ pmax(V_0 - seq(1, n_items) * V_1 + V_var, 1e-5),
  # Non-decision time
  ndt ~ ndt_0 + ndt_var
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = n_items,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm-2b",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx","rank_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "rank_idx","choice"),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7 ,0.9))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

## Covariate-dependent EAM

There are two general strategies for incorporating covariates into the
models.

In the first approach, model parameters are allowed to vary
systematically as a function of group or trial-level covariates.
Specifically, parameters are generated according to

$$\theta_{i} = \theta_{0} + \theta_{cov}\, X_{i},$$

where $\theta$ denotes the model parameters (e.g., drift rate, decision
boundary, or non-decision time), $X_{i}$ is the covariate value on trial
$i$, $\theta_{0}$ is the baseline (intercept) parameter, and
$\theta_{cov}$ quantifies the effect of the covariate. This formulation
is flexible and accommodates both continuous and discrete covariates.

When using simulation-based inference, the choice of summary statistics
must reflect the structure of the covariate. For continuous covariates,
the summary statistics should include the estimated regression intercept
and slope capturing the relationship between response times (RTs) and
the covariate. For discrete covariates, summary statistics typically
consist of RT quantiles computed separately for each covariate level,
together with accuracy measures for double-boundary EAMs.

``` r
# Set the number of accumulators in the model
n_items <- 1

# Set the covariate
cov1 <- rbinom(100,1,0.5)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  n_items ~ 1,
  # Decision boundary
  A_beta_0 ~ distributional::dist_uniform(0.5, 3),
  A_beta_1 ~ distributional::dist_uniform(-1, 1),
  # Drift rate
  V_beta_0 ~ distributional::dist_uniform(0.5, 3),
  V_beta_1 ~ distributional::dist_uniform(-1, 1),
  # Non-decision time
  ndt_beta_0 ~ distributional::dist_uniform(0, 1),
  ndt_beta_1 ~ distributional::dist_uniform(-1, 1),
  # Relative starting point
  Z_beta_0 ~ distributional::dist_uniform(-0.5, 0.5),
  Z_beta_1 ~ distributional::dist_uniform(-0.5, 0.5)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Covariate
  rlang::expr(cov1 ~ !!cov1)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_beta_0 + cov1 * Z_beta_1,
  # Decision boundary
  A_upper ~ (A_beta_0 + cov1 * A_beta_1), # upper 
  A_lower ~ -(A_beta_0  + cov1 * A_beta_1), # lower
  # Drift rate
  V ~ pmax(V_beta_0 + cov1 * V_beta_1, 1e-5),
  # Non-decision time
  ndt ~ pmax(ndt_beta_0 + cov1 * ndt_beta_1, 1e-5)
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = n_items,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm-2b",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx","rank_idx","cov1"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "rank_idx","choice","cov1"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7 ,0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

In the second approach, continuous covariates such as trial-level neural
signals are injected directly into the accumulation process by
modulating model parameters.

Specifically, the package allows users to link trial-level neural
measurements to EAM parameters through a latent-variable formulation. A
scaling parameter $s$ is introduced to map the neural signal onto the
appropriate parameter scale, while a variance term $\tau^{2}$ captures
the discrepancy between the observed neural signal and the latent
parameter value.

This formulation enables joint modeling of neural and behavioral data,
and allows formal tests of whether incorporating neural information
leads to improved model performance. Formally, a trial-level neural
signal $P_{i}$ (e.g., EEG or fMRI measurements) is linked to the
corresponding parameter $\theta_{i}$ via
$$\theta_{i} \sim \mathcal{N}(s \cdot P_{i},\,\tau^{2}).$$

``` r
# Set the number of accumulators in the model
n_items <- 1

# Set the covariate
cov1 <- rnorm(100,1,0.5)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  n_items ~ 1,
  # Decision boundary
  A_0 ~ distributional::dist_uniform(0.5, 3),
  # Drift rate
  V_coef ~ distributional::dist_uniform(0.5, 3),
  V_sigma ~ distributional::dist_uniform(0, 1),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0, 1),
  # Relative starting point
  Z_0 ~ distributional::dist_uniform(-0.5, 0.5)
)

# Specify the between-trial components (optional)
between_trial_formulas <- list(
  # Covariate
  rlang::expr(cov1 ~ !!cov1),
  V_latent ~ V_coef * stats::rnorm(1,mean=cov1,sd=V_sigma)
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  Z ~ Z_0,
  # Decision boundary
  A_upper ~ (A_0), # upper 
  A_lower ~ -(A_0), # lower
  # Drift rate
  V ~ pmax(V_latent, 1e-5),
  # Non-decision time
  ndt ~ ndt_0
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  # Pass the model information
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # Specify the simulation conditions and number of trials
  n_conditions_per_chunk = NULL, # NULL = automatic chunking
  n_conditions = 1000,
  n_trials_per_condition = 100,
  # Specify the number of accumulators and the number of recorded accumulators
  n_items = n_items,
  max_reached = n_items,
  # Specify the total elapsed time and time step
  max_t = 10,
  dt = 0.001,
  # Specify the noise structure
  noise_mechanism = "add",
  noise_factory = noise_factory,
  # Specify the model type
  model = "ddm-2b",
  # Specify the parallel computing settings
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
    lm_coef = lm(rt ~ cov1)$coefficients
  ) +
  summarise_by(
    .by = c("condition_idx", "choice"),
    rt_quantiles = quantile(rt, probs = c(0.005, 0.1, 0.3, 0.5, 0.7, 0.9, 0.995))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)
```

Reference:

Ratcliff, R. (1978). A theory of memory retrieval. Psychological Review,
85 (2), 59–108. <https://doi.org/10.1037/0033-295X.85.2.59>

Usher, M., & McClelland, J. L. (2001). The time course of perceptual
choice: The leaky, competing accumulator model. Psychological Review,
108 (3), 550–592. <https://doi.org/10.1037/0033-295X.108.3.550>

Brown, S. D., & Heathcote, A. (2008). The simplest complete model of
choice response time: Linear ballistic accumulation. Cognitive
Psychology, 57 (3), 153–178.
<https://doi.org/10.1016/j.cogpsych.2007.12.002>

Tillman, G., Van Zandt, T., & Logan, G. D. (2020). Sequential sampling
models without random between-trial variability: The racing diffusion
model of speeded decision making. Psychonomic Bulletin & Review, 27 (5),
911–936. <https://doi.org/10.3758/s13423-020-01719-6>

Wieschen, E. M., Voss, A., & Radev, S. T. (2020). Jumping to conclusion?
A Lévy flight model of decision making. The Quantitative Methods for
Psychology, 16 (2), 120–132. <https://doi.org/10.20982/tqmp.16.2.p120>
