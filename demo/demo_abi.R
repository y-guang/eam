###############
# model setup #
###############

# Define the number of accumulators
n_items <- 7
prior_params <- tibble::tibble(
  n_items = n_items
)

# Specify the prior distributions for free parameters
prior_formulas <- list(
  # parameters with distributions
  A_beta_0 ~ distributional::dist_uniform(0.50, 5.00),
  A_beta_1 ~ distributional::dist_uniform(0.01, 1.00),
  # V
  V_beta_0 ~ distributional::dist_uniform(0.5, 3.00),
  V_beta_1 ~ distributional::dist_uniform(0.01, 0.3),
  V_sigma ~ distributional::dist_uniform(0.01, 1.0),
  # ndt
  ndt_beta_0 ~ distributional::dist_uniform(-1, 1),
  # noise param
  noise_coef ~ 1
)


# Specify the between-trial components
between_trial_formulas <- list(
  # random group binomial
  V_var ~ distributional::dist_normal(0, V_sigma)
)

# Specify the item-level parameters
item_formulas <- list(
  A ~ A_beta_0 + seq(1, n_items) * A_beta_1,
  V ~ pmax(V_beta_0 - seq(1, n_items) * V_beta_1 + V_var, 1e-5),
  ndt ~ ndt_beta_0
)

# Specify the diffusion noise
noise_factory <- function(context) {
  function(n, dt) {
    rnorm(n, mean = 0, sd = sqrt(dt))
  }
}

sim_config <- new_simulation_config(
  prior_params = prior_params,
  prior_formulas = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas = item_formulas,
  n_conditions_per_chunk = NULL, # automatic chunking
  n_conditions = 500,
  n_trials_per_condition = 100,
  n_items = n_items,
  max_reached = n_items,
  max_t = 60,
  dt = 0.001,
  noise_mechanism = "add",
  noise_factory = noise_factory,
  model = "ddm",
  parallel = TRUE,
  n_cores = NULL, # Will use default: detectCores() - 1
  rand_seed = NULL # Will use default random seed
)


# output temporary path setup
temp_base_path <- tempfile("eam_demo")
# remove if exists
if (dir.exists(temp_base_path)) {
  unlink(temp_base_path, recursive = TRUE)
}
temp_output_path <- file.path(temp_base_path, "output")
cat("Temporary base path:\n")
cat(temp_base_path, "\n")

##################
# Run simulation #
##################
sim_output <- run_simulation(
  config = sim_config,
  output_dir = temp_output_path
)

#####################
# abi model prepare #
#####################

abi_input <- build_abi_input(
  sim_output,
  theta = c(
    "A_beta_0", "A_beta_1", "V_beta_0", "V_beta_1", "V_sigma", "ndt_beta_0"
  ),
  Z = c(
    "item_idx",
    "rt"
  ),
  train_ratio = 0.8,
  test_ratio = 0.1
)

#####################
# user define model #
#####################

point_estimator <- "
  d = 14    # dimension of each replicate
  w = 32   # number of neurons in each hidden layer

  # Layer to ensure valid estimates
  final_layer = Parallel(
      vcat,
      Dense(w, 1, softplus),
      Dense(w, 1, softplus),
      Dense(w, 1, softplus),
      Dense(w, 1, softplus),
      Dense(w, 1, softplus),
      Dense(w, 1, softplus)
    )

  psi = Chain(Dense(d, w, relu), Dense(w, w, relu), Dense(w, w, relu))
  phi = Chain(Dense(w, w, relu), Dense(w, w, relu), final_layer)
  deepset = DeepSet(psi, phi)
  estimator = PointEstimator(deepset)
"

trained_estimator <- train(
  point_estimator,
  theta_train = abi_input$theta_train,
  Z_train = abi_input$Z_train,
  theta_val = abi_input$theta_val,
  Z_val = abi_input$Z_val,
  epochs = 50,
  stopping_epochs = 20
)

####################
# cross validation #
####################
assessment <- abi_assess(
  trained_estimator,
  abi_input,
  estimator_name = "NBE"
)

plot_cv_recovery(assessment)

##################
# point estimate #
##################
point_est <- estimate(trained_estimator, abi_input$Z_test[[1]])
# TODO: impl it
