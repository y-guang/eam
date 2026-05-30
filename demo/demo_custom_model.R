######################
# custom model setup #
######################
n_items <- 1

prior_formulas <- list(
  # single-bound threshold for the custom backend
  A_base ~ distributional::dist_uniform(0.05, 0.40),
  # scale used by the custom noise factory
  noise_sd ~ distributional::dist_uniform(0.50, 1.50),
  ndt ~ 0
)

between_trial_formulas <- list()

item_formulas <- list(
  A ~ A_base,
  ndt ~ ndt
)

noise_factory <- function(context) {
  noise_sd <- context$noise_sd

  function(n, dt) {
    stats::rnorm(n, mean = 0, sd = noise_sd)
  }
}

####################
# simulation setup #
####################
sim_config <- new_simulation_config(
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions_per_chunk = NULL,
  n_conditions = 100,
  n_trials_per_condition = 50,
  n_items = n_items,
  max_reached = n_items,
  max_t = 5,
  dt = 0.01,
  noise_factory = noise_factory,
  model = "custom-model",
  parallel = FALSE,
  rand_seed = NULL
)
print(sim_config)

temp_base_path <- tempfile("eam_custom_model_demo")
if (dir.exists(temp_base_path)) {
  unlink(temp_base_path, recursive = TRUE)
}
temp_output_path <- file.path(temp_base_path, "output")
cat("Temporary base path:\n")
cat(temp_base_path, "\n")

##################
# run simulation #
##################
sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

#####################
# abc model prepare #
#####################
head(sim_output$open_dataset())

summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    rt_mean = mean(rt),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.5, 0.9)),
    evidence_mean = mean(evidence)
  )

simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) {
    summary_pipe(cond_df)
  }
)

simulation_sumstat <- simulation_sumstat[complete.cases(simulation_sumstat), ]

# Pretend condition 1 is observed data.
observed_data <- sim_output$open_dataset() |>
  dplyr::filter(chunk_idx == 1, condition_idx == 1) |>
  dplyr::collect()
target_sumstat <- summary_pipe(observed_data)

abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = simulation_sumstat,
  target_summary = target_sumstat,
  param = c("A_base", "noise_sd")
)

#####################
# ABC model fitting #
#####################
abc_rejection_model <- abc_abc(
  abc_input = abc_input,
  tol = 0.2,
  method = "rejection"
)

summarise_posterior_parameters(
  abc_rejection_model,
  ci_level = 0.95
)

plot_posterior_parameters(
  abc_rejection_model,
  abc_input
)

#############
# posterior #
#############
posterior_params <- abc_posterior_bootstrap(
  abc_rejection_model,
  n_samples = 1
)

post_sim_config <- update_config_from_posterior(
  config = sim_config,
  posterior_params = posterior_params,
  n_conditions = 1,
  n_trials_per_condition = 200
)

post_output <- run_simulation(post_sim_config)

plot_rt(
  post_output,
  observed_data,
  facet_x = c(),
  facet_y = c()
)

abc_posterior_predictive_check(
  config = sim_config,
  abc_result = abc_rejection_model,
  observed_df = observed_data,
  n_conditions = 1,
  n_trials_per_condition = 200,
  rt_facet_x = c(),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c(),
  accuracy_facet_y = c()
)
