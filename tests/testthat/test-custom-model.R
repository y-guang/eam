test_that("custom model does not reach the upper boundary on the first down step", {
  result <- eam:::accumulate_evidence_custom_model(
    A = c(0),
    step_size = c(1),
    Z = c(0),
    ndt = c(0),
    max_t = 0.1,
    dt = 0.1,
    max_reached = 1,
    noise_func = function(n, dt) rep(1, n)
  )

  expect_equal(length(result$item_idx), 0)
  expect_equal(length(result$rt), 0)
  expect_equal(length(result$evidence), 0)
})

test_that("custom model reaches the upper boundary after two fixed steps", {
  result <- eam:::accumulate_evidence_custom_model(
    A = c(0),
    step_size = c(1),
    Z = c(0),
    ndt = c(0),
    max_t = 0.2,
    dt = 0.1,
    max_reached = 1,
    noise_func = function(n, dt) rep(1, n)
  )

  expect_equal(result$item_idx, 1L)
  expect_equal(result$rt, 0.2)
  expect_equal(result$evidence, 0)
})

test_that("custom model returns the expected output columns", {
  result <- eam:::accumulate_evidence_custom_model(
    A = c(0),
    step_size = c(1),
    Z = c(0),
    ndt = c(0),
    max_t = 0.2,
    dt = 0.1,
    max_reached = 1,
    noise_func = function(n, dt) rep(1, n)
  )

  expect_true(all(c("item_idx", "rt", "evidence") %in% names(result)))
  expect_equal(length(result$item_idx), length(result$rt))
  expect_equal(length(result$item_idx), length(result$evidence))
})
