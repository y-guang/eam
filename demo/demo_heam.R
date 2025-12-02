prior_formulas <- list(
  n_items  ~ 1,
  A_mu ~ distributional::dist_uniform(1.0, 3.0),
  A_sigma ~ distributional::dist_uniform(0.01, 0.5),
  V_mu ~ distributional::dist_uniform(0.5, 2.0),
  V_sigma ~ distributional::dist_uniform(0.01, 0.5),
  ndt_mu ~ distributional::dist_uniform(0.01, 2.0),
  ndt_sigma ~ distributional::dist_uniform(0.01, 0.5),
  Z_mu  ~ distributional::dist_uniform(-0.5, 0.5),
  Z_sigma  ~ distributional::dist_uniform(0.01, 0.3)
)

between_trial_formulas <- list(
  subject_idx ~ rep(seq(1, 5),100),
  A_i ~ rep(stats::rnorm(5, A_mu, A_sigma), 100),
  V_i ~ rep(stats::rnorm(5, V_mu, V_sigma), 100),
  ndt_i ~ rep(stats::rnorm(5, ndt_mu, ndt_sigma), 100),
  Z_i ~ rep(stats::rnorm(5, Z_mu, Z_sigma), 100)
)

item_formulas <- list(
  A_upper ~ A_i,
  A_lower ~ -A_i,
  V ~ pmax(V_i,1e-5),
  ndt ~ pmax(ndt_i,1e-5),
  Z ~ Z_i
)

noise_factory <- function(context) {
  function(n, dt) rnorm(n, mean = 0, sd = sqrt(dt))
}

sim_config <- new_simulation_config(
  prior_formulas         = prior_formulas,
  between_trial_formulas = between_trial_formulas,
  item_formulas          = item_formulas,
  n_conditions_per_chunk = NULL,
  n_conditions           = 500,
  n_trials_per_condition = 500,
  n_items                = 1,
  max_reached            = 1,
  max_t                  = 30,
  dt                     = 0.001,
  noise_mechanism        = "add",
  noise_factory          = noise_factory,
  model                  = "ddm-2b",
  parallel               = T
)

# output temporary path setup
temp_output_path <- tempfile("eam_demo_output")
# remove if exists
if (dir.exists(temp_output_path)) {
  unlink(temp_output_path, recursive = TRUE)
}

sim_output <- run_simulation(config = sim_config, output_dir = temp_output_path)

summary_pipe <-
  summarise_by(
    .by = c("condition_idx"),
    acc = sum(choice == 1) / sum(!is.na(choice)),
  ) +
  summarise_by(
    .by = c("condition_idx", "choice"),
    rt_quantiles = quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))
  )

simulation_sumstat <- map_by_condition(
  sim_output,
  .progress = TRUE,
  .parallel = FALSE,
  function(cond_df) {
    subject_df <- cond_df |>
      dplyr::group_by(condition_idx, subject_idx) |>
      dplyr::summarise(
        participant_rt_sd = sd(rt, na.rm = TRUE),
        participant_rt_q = list(quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))),
        participant_acc = sum(choice == 1) / sum(!is.na(choice)),
        .groups = "drop"
      ) |>
      tidyr::unnest_wider(participant_rt_q, names_sep = "_")

    subject_choice_df <- cond_df |>
      dplyr::group_by(condition_idx, subject_idx, choice) |>
      dplyr::summarise(
        participant_rt_sd = sd(rt, na.rm = TRUE),
        participant_rt_q = list(quantile(rt, probs = c(0.1, 0.3, 0.5, 0.7, 0.9))),
        .groups = "drop"
      ) |>
      tidyr::unnest_wider(participant_rt_q, names_sep = "_")

    summary_pipe(cond_df) +
      summarise_by(
        .data = subject_df,
        .by = c("condition_idx"),
        rt_sd_sd = sd(participant_rt_sd, na.rm = TRUE),
        q10_sd = sd(`participant_rt_q_10%`, na.rm = TRUE),
        q30_sd = sd(`participant_rt_q_30%`, na.rm = TRUE),
        q50_sd = sd(`participant_rt_q_50%`, na.rm = TRUE),
        q70_sd = sd(`participant_rt_q_70%`, na.rm = TRUE),
        q90_sd = sd(`participant_rt_q_90%`, na.rm = TRUE),
        acc_sd = sd(participant_acc, na.rm = TRUE)
      ) +
      summarise_by(
        .data = subject_choice_df,
        .by = c("condition_idx", "choice"),
        rt_sd_sd = sd(participant_rt_sd, na.rm = TRUE),
        q10_sd = sd(`participant_rt_q_10%`, na.rm = TRUE),
        q30_sd = sd(`participant_rt_q_30%`, na.rm = TRUE),
        q50_sd = sd(`participant_rt_q_50%`, na.rm = TRUE),
        q70_sd = sd(`participant_rt_q_70%`, na.rm = TRUE),
        q90_sd = sd(`participant_rt_q_90%`, na.rm = TRUE),
      )
  }
)


simulation_sumstat[is.na(simulation_sumstat)] <- 0
condition_idx  <- 1
target_sumstat <- simulation_sumstat[condition_idx, ]



abc_input <- build_abc_input(
  simulation_output = sim_output,
  simulation_summary = simulation_sumstat,
  target_summary     = target_sumstat,
  param = c("A_mu","A_sigma", "V_mu","V_sigma", "ndt_mu","ndt_sigma", "Z_mu","Z_sigma")
)

abc_fit <- abc::abc(
  target = abc_input$target,
  param  = abc_input$param,
  sumstat= abc_input$sumstat,
  tol    = 0.05,
  method = "neuralnet",
  sizenet= 8,
  maxit  = 10000,
  lambda = 1e-2,
  kernel = "epanechnikov",
  transf = c("log", "none", "log", "none","log","none","none", "none")
)

abc_cv <- abc::cv4abc(
  param   = abc_input$param,
  sumstat = abc_input$sumstat,
  abc.out = abc_fit,
  nval    = 100,
  tols    = c(0.05)
)

