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
  n_test = 100
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

trained_point_estimator <- abi_train(
  estimator = point_estimator,
  abi_input = abi_input,
  epochs = 50,
  stopping_epochs = 20
)

####################
# cross validation #
####################
assessment <- abi_assess(
  trained_estimator = trained_point_estimator,
  estimator_name = "NBE"
)

plot_cv_recovery(assessment)

##################
# point estimate #
##################
point_est <- abi_estimate(
  trained_estimator = trained_point_estimator,
  Z = abi_input$Z_test[[1]]
)

point_est

###########################
# posterior simulation    #
# using point estimates   #
###########################

# Convert point estimates to posterior_params format
posterior_params <- tibble::as_tibble(
  c(
    setNames(as.list(point_est[, 1]), rownames(point_est)),
    list(n_items = n_items)
  )
)

# Get observed data from simulation output
# pretend observed data is condition 1
observed_data <- sim_output$open_dataset() |>
  dplyr::filter(chunk_idx == 1, condition_idx == 1) |>
  dplyr::collect()

# manual way (kept as reference)
manual_post_sim_config <- sim_config
manual_post_sim_config$prior_params <- posterior_params
manual_post_sim_config$prior_formulas <- list(noise_coef ~ 1) # exclude drawn posteriors

# recommended helper way
post_sim_config <- update_config_from_posterior(
  config = sim_config,
  posterior_params = posterior_params
)

temp_output_path_post <- file.path(temp_base_path, "posterior_output")

post_output <- run_simulation(
  config = post_sim_config,
  output_dir = temp_output_path_post
)

# plot the posterior rt and accuracy
plot_rt(
  post_output,
  observed_data,
  facet_x = c("item_idx"),
  facet_y = c()
)

plot_accuracy(
  post_output,
  observed_data,
  facet_x = c("ndt_beta_0"),
  facet_y = c()
)

# third way: high-level wrapper for point estimator
abi_posterior_predictive_check(
  config = sim_config,
  trained_estimator = trained_point_estimator,
  estimator_type = "point",
  observed_df = observed_data,
  Z = abi_input$Z_test[[1]],
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c("ndt_beta_0"),
  accuracy_facet_y = c()
)

########################
# posterior estimation #
########################
posterior_estimator <- "
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
  w = 6
  q = NormalisingFlow(w, w)
  estimator = PosteriorEstimator(q,deepset)
"

trained_posterior_estimator <- abi_train(
  estimator = posterior_estimator,
  abi_input = abi_input,
  epochs = 50,
  stopping_epochs = 20
)

# Sample from posterior distribution
posterior_samples <- abi_sample_posterior(
  trained_estimator = trained_posterior_estimator,
  N = 1000
)
posterior_samples

# Summarise posterior parameters for each dataset
posterior_summary <- summarise_posterior_parameters(posterior_samples)
print(posterior_summary)

############################################
# cross-validation: posterior recovery    #
# using median of posterior samples       #
############################################

# Method 1: Using trained_estimator to get true values
plot_cv_recovery(
  posterior_samples,
  trained_estimator = trained_posterior_estimator
)

# Method 2: Providing true parameter values directly
plot_cv_recovery(
  posterior_samples,
  theta = abi_input$theta_test
)

#############################################
# posterior simulation                      #
# using median of posterior samples         #
#############################################

# Extract median estimates from first dataset's posterior samples
dataset_1_samples <- posterior_samples |>
  dplyr::filter(dataset_id == 1)

posterior_medians <- dataset_1_samples |>
  dplyr::select(-dataset_id) |>
  dplyr::summarise(dplyr::across(dplyr::everything(), stats::median))

# Convert to posterior_params format
posterior_params_from_samples <- tibble::as_tibble(
  c(
    as.list(posterior_medians),
    list(n_items = n_items)
  )
)

# manual way (kept as reference)
manual_post_sim_config_2 <- sim_config
manual_post_sim_config_2$prior_params <- posterior_params_from_samples
manual_post_sim_config_2$prior_formulas <- list(noise_coef ~ 1) # exclude drawn posteriors

# recommended helper way
post_sim_config_2 <- update_config_from_posterior(
  config = sim_config,
  posterior_params = posterior_params_from_samples
)

temp_output_path_post_2 <- file.path(temp_base_path, "posterior_output_2")

post_output_2 <- run_simulation(
  config = post_sim_config_2,
  output_dir = temp_output_path_post_2
)

# plot the posterior rt and accuracy
plot_rt(
  post_output_2,
  observed_data,
  facet_x = c("item_idx"),
  facet_y = c()
)

plot_accuracy(
  post_output_2,
  observed_data,
  facet_x = c("ndt_beta_0"),
  facet_y = c()
)

# third way: high-level wrapper for posterior estimator
abi_posterior_predictive_check(
  config = sim_config,
  trained_estimator = trained_posterior_estimator,
  estimator_type = "posterior",
  observed_df = observed_data,
  Z = abi_input$Z_test,
  posterior_dataset_id = 1,
  posterior_n_samples = 1000,
  rt_facet_x = c("item_idx"),
  rt_facet_y = c(),
  accuracy_x = "item_idx",
  accuracy_facet_x = c("ndt_beta_0"),
  accuracy_facet_y = c()
)
