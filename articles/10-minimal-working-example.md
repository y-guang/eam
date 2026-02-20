# Getting Started: A Minimal Working Example

This section aims to help you grasp the basic workflow to run this
package. In this section, we will outline the main functionality of the
package and demonstrating a minimal working example that can be run with
minimal knowledge about EAMs.

The workflow implemented in **eam** follows the standard workflow in
simulation-based inference. First, we begin by specifying a
data-generating process, simulate data under a range of parameter
values, and then use simulation-based inference to learn which
parameters are most consistent with the observed data.

Concretely, the workflow consists of four steps:

1.  **Model specification and simulation**: Define an evidence
    accumulation model by specifying its structural components
    (boundaries, drift, noise, and non-decision processes), and simulate
    synthetic datasets from the prior.
2.  **Summary statistics computation**: Reduce both simulated and
    observed data to informative summary statistics that capture key
    data patterns.
3.  **Parameter estimation and recovery**: Use ABC (or ABI) to infer
    posterior distributions over parameters, and evaluate whether the
    inference procedure can reliably recover known parameters.
4.  **Model evaluation and comparison**: Assess model adequacy using
    posterior predictive checks, and compare alternative model
    specifications.

The following sections walk through these steps in detail using a simple
DDM example, before extending the workflow to more complex models.

------------------------------------------------------------------------

In this example, we start with a simple three-parameter two-boundary
Diffusion Decision Model (DDM).

Although the DDM has a trackable likelihood, we deliberately treat it as
a generative model here. This allows us to demonstrate the full
simulation-based workflow in a setting where the ground truth is known.

Here, we adopt a slightly different parameterization from the
conventional DDM: instead of assuming accumulation from a positive
starting point toward 0 or $a$, evidence is initialized at zero and
evolves toward symmetric bounds at $a$ and $- a$.

### Description of the model

The details of this model is listed below:

**Priors on global parameters** $$\begin{aligned}
A_{0} & {\sim \text{Uniform}(1,5),} \\
V_{0} & {\sim \text{Uniform}(0.5,3),} \\
{ndt_{0}} & {\sim \text{Uniform}(0,1),} \\
\rho_{0} & {= 0.5.}
\end{aligned}$$

**Item-level parameterization** $$\begin{aligned}
\rho & {= \rho_{0},} \\
A_{\text{upper}} & {= \rho A_{0},} \\
A_{\text{lower}} & {= - \rho A_{0},} \\
V & {= V_{0},} \\
{ndt} & {= ndt_{0}.}
\end{aligned}$$

**Evidence accumulation dynamics**
$$dX(t) = V\, dt + dW(t),\qquad dW(t) \sim \mathcal{N}(0,dt).$$

A decision is made when $X(t)$ first reaches either $A_{\text{upper}}$
or $A_{\text{lower}}$, and the observed response time is

$$RT = T_{\text{decision}} + ndt.$$

### Step one: Model setup

First, we load the required packages.

``` r
# Load necessary packages
library(eam)
library(dplyr)

# Set a random seed for reproducibility
set.seed(1)
```

Then, we specify the model configuration according to the setup
described above.

``` r
#######################
# Model specification #
#######################
# Define the number of accumulators
n_items <-1

# Set the number of accumulators in the model
prior_params <- tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(1, 5),
  # Drift rate
  V_0 ~ distributional::dist_uniform(0.5, 3),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0,1),
  # Relative starting point
  rho_0 ~ 0.5
)

# Specify the between-trial components (skipped here)
between_trial_formulas <- list(
)

# Specify the item-level parameters
item_formulas <- list(
  # Relative starting point
  rho ~ rho_0,
  # Decision boundary
  A_upper ~ rho*(A_0), # upper 
  A_lower ~ -rho*(A_0), # lower
  # Drift rate
  V ~ V_0,
  # Non-decision time
  ndt ~ ndt_0
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}
```

------------------------------------------------------------------------

### Step two: Data simulation

Once the model is specified, we can proceed to data simulation. The
simulation step generates a large collection of synthetic datasets by
sampling parameters from their prior distributions and simulating data
from the corresponding generative model. Each simulated dataset
represents a possible outcome implied by the assumed model.

``` r
####################
# Simulation setup #
####################
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
  parallel = FALSE, # In tutorial, we disable parallelization, but you are encouraged to enable it locally
  n_cores = NULL, # When parallel enabled, will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

# Output temporary path setup
temp_output_path <- tempfile("eam_demo_output")

##################
# Run simulation #
##################
sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)
```

------------------------------------------------------------------------

### Step three: Load observed data

For observed data, we create a small dataset using the **rtdists**
package, which provides fast simulators for standard DDM. Specifically,
we simulate N=500 trials from a two-boundary DDM with fixed parameters
($a$,$v$,$t0$) where a controls boundary separation, $v$ is the drift
rate, and $t0$ captures non-decision time.

The function *rdiffusion()* returns response labels (“upper”/“lower”)
and response times. For consistency with the data format produced by our
simulation engine, we recode responses into a numeric choice variable (1
for the upper boundary and -1 for the lower boundary), and we add a
condition_idx field to indicate that all trials belong to a single
experimental condition

``` r
############################
# Observed data generation #
############################

library(rtdists)


N <- 500

pars <- list(
  a  = 2.0,   # Decision boundary
  v  = 2.0,   # Drift rate
  t0 = 0.5  # Non-decision time
)

# rdiffusion() will return responses and RTs from a standard DDM 
observed_data <- rdiffusion(n = N, a = pars$a, v = pars$v, t0 = pars$t0)

# Recode the data to be consistent with simulated data
observed_data$choice <- ifelse(observed_data $response == "upper", 1, -1)
observed_data$condition_idx <- 1
```

------------------------------------------------------------------------

### Step four: Extract summary statistics

we define a summary pipeline that extracts two types of common summary
statistics of the DDM data: (i) the accuracy and (ii) RT quantiles (10%,
30%, 50%, 70%, 90%) computed separately for each choice category (1
vs. -1).

We then apply the same summary procedure to every simulated dataset to
obtain *simulation_sumstat*, and to the observed dataset to obtain
*target_sumstat*. Finally, build_abc_input() aligns the simulated and
observed summaries into a consistent structure.

``` r
#####################
# abc model prepare #
#####################

# Define the summary procedure
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "choice"),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))
  )

# Calculate simulated summary statistics
simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE, # turn on if you want to speed up
  function(cond_df) summary_pipe(cond_df)
)

# Calculate observed summary statistics
target_sumstat <- summary_pipe(observed_data)

# Align the simulated and observed summary statistics
abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = simulation_sumstat,
  target_summary     = target_sumstat,
  param = c("A_0","V_0","ndt_0")
)
```

------------------------------------------------------------------------

### Step five: Fit the model

With the simulated and observed summary statistics aligned, we can now
estimate the posterior distribution of the model parameters using
Approximate Bayesian Computation (ABC).

Specifically, we fit an ABC model by comparing the simulated summary
statistics to the observed summary statistics. Then we retain (or
reweight) parameter draws that best reproduce the observed summaries
under a tolerance level (tol=0.05).

Here we use a neural-net-adjusted ABC variant (method = “neuralnet”),
which learns a flexible mapping from summary statistics to parameters to
improve posterior approximation.

These diagnostics help verify whether the posterior concentrates on
plausible regions of the parameter space and whether the recovered
parameters are consistent with the parameters in the *rdiffusion()*
model.

``` r
########################
# Parameter estimation #
########################

# Fit abc model (neuralnet)
abc_fit <- abc::abc(
  target = abc_input$target,
  param  = abc_input$param,
  sumstat= abc_input$sumstat,
  tol    = 0.05,
  method = "neuralnet"
)
#> Warning: All parameters are "none" transformed.
#> 12345678910
#> 12345678910
```

------------------------------------------------------------------------

After fitting, we summarize the posterior means/medians and 95% credible
intervals and visualize the resulting posterior distributions.

As shown, the true parameter values underlying the observed data lie
well within the 95% credible intervals of the posterior distributions.

``` r
# Posterior estimation check
summarise_posterior_parameters(
  abc_fit,
  ci_level = 0.95
)
#>   parameter      mean    median ci_lower_0.025 ci_upper_0.975
#> 1       A_0 1.8527969 1.8472045      1.6285389      2.1260080
#> 2       V_0 1.9133499 1.9342754      1.7349258      2.0046695
#> 3     ndt_0 0.4854268 0.4860683      0.4370122      0.5083276

plot_posterior_parameters(
  abc_fit,
  abc_input
)
```

![plot of chunk
unnamed-chunk-8](10-minimal-workflow/unnamed-chunk-8-1.svg)

plot of chunk unnamed-chunk-8

------------------------------------------------------------------------

### Step six: Model evaluation

The next step is to evaluate parameter recovery for the model. To do so,
we run *cv4abc()* as a cross-validation procedure.

First, we specify the number of validation datasets (N=100). The
function then randomly samples N conditions from the simulated summary
statistics, treats their associated parameter values as known ground
truth, and re-estimates the parameters using the fitted ABC object under
the same tolerance level.

Recovery performance is visualized using *plot_cv_recovery()*, which
compares the estimated parameters with their true values across
validation datasets.

Good recovery is indicated by a high correlation between estimated and
true parameters (good: $r \geq 0.75$; excellent: $r \geq 0.90$) and by
estimates clustering closely around the identity line with minimal
residual dispersion.

The resid_tol option trims extreme residuals (here retaining the central
99%), making the main recovery pattern easier to inspect.

As shown, the three parameters exhibit excellent recovery.

``` r
# Parameter recovery check
plot_cv_recovery(
  abc_cv,
  n_rows = 3,
  n_cols = 1,
  resid_tol = 0.99,
  interactive = FALSE
)
#> Error:
#> ! object 'abc_cv' not found
```

------------------------------------------------------------------------

As a final diagnostic, we perform a posterior predictive check to assess
the adequacy of the fitted model.

Specifically, we generate the posterior data using posterior median
estimates obtained from the ABC analysis. The resulting posterior
predictive simulations are then compared with the observed dataset.

By visually inspecting the overlap between simulated and observed RT
distributions and accuracy rates, we can evaluate whether the fitted
model is able to reproduce key empirical patterns.

``` r
##############################
# Posterior predictive check #
##############################

# Use posterior median as input
prior_formulas <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(1.96, 1.96),
  # Drift rate
  V_0 ~ distributional::dist_uniform(2.10, 2.10),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0.48,0.48),
  # Relative starting point
  rho_0 ~ 0.5
)

# Run the posteior simulation
sim_config_post <- new_simulation_config(
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions_per_chunk = NULL, # automatic chunking
  n_conditions = 1,
  n_trials_per_condition = 500,
  n_items = n_items,
  max_reached = n_items,
  max_t = 10,
  dt = 0.001,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "ddm-2b",
  parallel = FALSE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)

t0 <- Sys.time()
temp_output_path <- tempfile("eam_demo_post_output")
sim_output_post <- run_simulation(config = sim_config_post, output_dir = temp_output_path)

post_output <- sim_output_post
observed_data$item_idx <- 1

# Plot the posterior rt and accuracy
plot_rt(
  post_output,
  observed_data,
  facet_x = c("item_idx"),
  facet_y = c()
)
```

![plot of chunk
unnamed-chunk-10](10-minimal-workflow/unnamed-chunk-10-1.svg)

plot of chunk unnamed-chunk-10

``` r

plot_accuracy(
  post_output,
  observed_data,
  facet_x = c(),
  facet_y = c()
)
```

## ![plot of chunk unnamed-chunk-10](10-minimal-workflow/unnamed-chunk-10-2.svg)

### Step seven (optional): Model comparison

Beyond parameter estimation, the **eam** package also supports model
comparison within a simulation-based inference framework.

In this example, we construct an alternative model by deliberately
modifying the prior specification of the relative starting point
parameter $\rho$, while keeping all other components of the model
unchanged. This allows us to isolate the contribution of this parameter
assumption to overall model fit. Synthetic data are then generated under
the alternative model, and the same summary statistics pipeline is
applied to ensure comparability across models.

Model comparison is conducted using the *abc_postpr()* function, which
estimates posterior model probabilities based on Approximate Bayesian
Computation. Intuitively, this procedure assesses which model is more
likely to have generated the observed data by comparing the proximity of
simulated summary statistics from each model to the target summary
statistics, given a fixed tolerance level.

The resulting posterior probabilities indicate the relative likelihood
that the observed data were generated by each candidate model. These
probabilities can be summarized using Bayes factors, which quantify the
strength of evidence in favor of one model over another. Conventionally,
Bayes factors greater than 3 or smaller than 1/3 are interpreted as
providing substantial evidence for one model relative to its competitor.

``` r
# Deliberately change the rho in the alternative model
prior_formulas_alt <- list(
  # Decision boundary
  A_0 ~ distributional::dist_uniform(1, 5),
  # Drift rate
  V_0 ~ distributional::dist_uniform(0.5, 3),
  # Non-decision time
  ndt_0 ~ distributional::dist_uniform(0,1),
  # Relative starting point
  rho_0 ~ 0.7
)

sim_config_alt <- sim_config
sim_config_alt$prior_formulas <- prior_formulas_alt

temp_output_path <- tempfile("eam_demo_output_alt")

# Run the simulation
sim_output_alt <- run_simulation(
  config = sim_config_alt,
  output_dir = temp_output_path
)

# Calculate simulated summary statistics for the alternative model
simulation_sumstat_alt <- map_by_condition(
  sim_output_alt,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) summary_pipe(cond_df)
)


abc_input_alt <- build_abc_input(
  simulation_output = sim_output_alt,
  simulation_summary = simulation_sumstat_alt,
  target_summary = target_sumstat,
  param = c("A_0","V_0","ndt_0")
)

# Run the model comparison
postpr_result <- abc_postpr(
  sumstats = list(
    abc_input$sumstat,
    abc_input_alt$sumstat
  ),
  target = abc_input$target,
  tol = 0.05,
  method = "rejection"
)

summary(postpr_result)
#> Call: 
#> abc::postpr(target = target, index = index, sumstat = sumstat, 
#>     tol = 0.05, method = "rejection")
#> Data:
#>  postpr.out$values (100 posterior samples)
#> Models a priori:
#>  model_1, model_2
#> Models a posteriori:
#>  model_1, model_2
#> 
#> Proportion of accepted simulations (rejection):
#> model_1 model_2 
#>    0.59    0.41 
#> 
#> Bayes factors:
#>         model_1 model_2
#> model_1  1.0000  1.4390
#> model_2  0.6949  1.0000
```

This is the end of this example.

------------------------------------------------------------------------

This simple DDM example serves as a reference template for the rest of
the tutorial. Once this workflow is clear, extending it to more complex
models in eam mainly involves modifying the model components, while the
overall inference pipeline remains unchanged.
