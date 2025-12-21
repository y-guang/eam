###############
# model setup #
###############
library(eam)
library(dplyr)

# define the condition data generate logic
n_items <- 3
prior_params <- tibble(
  n_items = n_items
)

prior_formulas <- list(
  # V
  V_beta_1 ~ distributional::dist_lognormal(-1, 0.5),
  V_beta_group ~ distributional::dist_uniform(0.1, 0.3)
)

between_trial_formulas <- list(
  group ~ distributional::dist_binomial(1, 0.5)
)

item_formulas <- list(
  A_upper ~ 1,
  A_lower ~ -1,
  V ~ seq(1, n_items) * V_beta_1 + group * V_beta_group,
  ndt ~ 0
)

noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

####################
# simulation setup #
####################
base_dir <- "./inst/extdata/rdm_minimal"

sim_config <- new_simulation_config(
  prior_params = prior_params,
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  # use chunk size = conditions to minimize output dataset size.
  # it is a specific trick to minimize the package size, avoid this in real use.
  n_conditions_per_chunk = 500,
  n_conditions = 500,
  n_trials_per_condition = 100,
  n_items = n_items,
  max_reached = n_items,
  max_t = 10,
  dt = 0.001,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "rdm",
  parallel = FALSE,
  n_cores = NULL,
  rand_seed = 42
)
output_path <- file.path(base_dir, "simulation")
if (dir.exists(output_path)) {
  unlink(output_path, recursive = TRUE)
}
dir.create(output_path, recursive = TRUE)

##################
# run simulation #
##################
sim_output <- run_simulation(
  config = sim_config,
  output_dir = output_path
)

###################
# run observation #
###################
true_prior_formulas <- list(
  # V
  V_beta_1 ~ 0.3,
  V_beta_group ~ 0.2
)

obs_config <- new_simulation_config(
  prior_params = prior_params,
  prior_formulas = true_prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions_per_chunk = 1,
  n_conditions = 1,
  n_trials_per_condition = 2000,
  n_items = n_items,
  max_reached = n_items,
  max_t = 10,
  dt = 0.01,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "rdm",
  parallel = FALSE,
  n_cores = NULL,
  rand_seed = 26
)

obs_output <- run_simulation(
  config = obs_config
)

obs_dataset <- obs_output$open_dataset()
obs_output_path <- file.path(base_dir, "observation")
dir.create(obs_output_path, showWarnings = FALSE, recursive = TRUE)

obs_df <- obs_dataset |>
  select(
    condition_idx,
    trial_idx,
    item_idx,
    rank_idx,
    group,
    rt,
    choice
  ) |>
  collect() |>
  mutate(
    rt = round(rt, 3)
  )

obs_df |>
  write.csv(
    file = file.path(obs_output_path, "observation_data.csv"),
    row.names = FALSE
  )

########
# load #
########
# sim_output_path <- system.file("extdata", "rdm_minimal", "simulation", package = "eam")
# sim_output <- load_simulation_output(sim_output_path)
# obs_df <- read.csv(file.path(system.file("extdata", "rdm_minimal", "observation", package = "eam"), "observation_data.csv"))

#####################
# abc model prepare #
#####################
summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    rt_mean = mean(rt),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))
  ) +
  summarise_by(
    .by = c("condition_idx", "item_idx"),
    rt_mean = mean(rt),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))
  ) +
  summarise_by(
    .by = c("condition_idx", "group"),
    rt_mean = mean(rt),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))
  )

sim_sumstat <- map_by_condition(
  sim_output,
  .progress = FALSE,
  .parallel = FALSE,
  function(cond_df) {
    summary_pipe(cond_df)
  }
)

dir.create(file.path(base_dir, "summary"), showWarnings = FALSE, recursive = TRUE)

sim_sumstat |> write.csv(
  file = file.path(base_dir, "summary", "simulation.csv"),
  row.names = FALSE
)

obs_sumstat <- obs_df |>
  summary_pipe()

obs_sumstat |> write.csv(
  file = file.path(base_dir, "summary", "observation.csv"),
  row.names = FALSE
)

abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = sim_sumstat,
  target_summary = obs_sumstat,
  param = c("V_beta_1", "V_beta_group")
)

dir.create(file.path(base_dir, "abc"), showWarnings = FALSE, recursive = TRUE)

abc_input |> saveRDS(file = file.path(base_dir, "abc", "abc_input.rds"))

#####################
# ABC model fitting #
#####################
abc_model <- abc::abc(
  target = abc_input$target,
  param = abc_input$param,
  sumstat = abc_input$sumstat,
  tol = 0.05,
  method = "neuralnet",
  sizenet = 3,
  maxit = 1000,
  lambda = 0.05,
  kernel = "epanechnikov",
  transf = c("log", "log")
)

abc_model |> saveRDS(file = file.path(base_dir, "abc", "abc_neuralnet_model.rds"))

abc_model$adj.values

posterior_params <- abc_posterior_bootstrap(
  abc_model,
  n_samples = 100
)

posterior_params$n_items <- 3

post_sim_config <- sim_config
post_sim_config$prior_params <- posterior_params
post_sim_config$prior_formulas <- list()

post_output <- run_simulation(
  config = post_sim_config
)

plot_rt(
  post_output,
  obs_df,
  facet_x = c("item_idx"),
  facet_y = c("group")
)

plot_accuracy(
  post_output,
  obs_df,
  facet_x = c("group"),
  facet_y = c()
)
