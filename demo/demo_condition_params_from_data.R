###############
# model setup #
###############
n_items <- 10

condition_param <- seq(1, 20)

library(rlang)
prior_formulas <- list(
  n_items ~ 10,
  # parameters with distributions
  expr(A_beta_0 ~ !!condition_param),
  A_beta_1 ~ distributional::dist_uniform(1.00, 10.00),
  # V
  V_beta_0 ~ distributional::dist_uniform(1.0, 5.0),
  V_beta_1 ~ distributional::dist_uniform(-0.50, -0.01),
  # ndt
  ndt ~ distributional::dist_uniform(0.01, 3.00),
  # noise param
  noise_coef ~ 1,
  # between trial varibaility
  sigma ~ distributional::dist_uniform(0.1, 3.00)
)

between_trial_formulas <- list(
  V_var ~ distributional::dist_normal(0, sigma)
)

item_formulas <- list(
  A ~ A_beta_0 + seq(1, n_items) * A_beta_1,
  V ~ V_beta_0 + seq(1, n_items) * V_beta_1 + V_var
)

noise_factory <- function(context) {
  noise_coef <- context$noise_coef

  function(n, dt) {
    noise_coef * rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

####################
# simulation setup #
####################
sim_config <- new_simulation_config(
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions_per_chunk = NULL, # automatic chunking
  n_conditions = 20,
  n_trials_per_condition = 100,
  n_items = n_items,
  max_reached = n_items,
  max_t = 100,
  dt = 0.01,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "ddm",
  parallel = TRUE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)
print(sim_config)

# output temporary path setup
temp_output_path <- tempfile("multieam_demo_output")
# remove if exists
if (dir.exists(temp_output_path)) {
  unlink(temp_output_path, recursive = TRUE)
}
cat("Temporary output path:\n")
cat(temp_output_path, "\n")

##################
# run simulation #
##################
sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)
result <- sim_output$open_dataset() |> dplyr::collect()
