test_that("accumulate_evidence_ddm_custom returns expected output", {
  result <- accumulate_evidence_ddm_custom(
    A = c(1),
    V = c(0.05),
    Z = c(0),
    ndt = c(0.2),
    max_t = 50,
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rep(0.01, n)
  )

  expect_true("item_idx" %in% names(result))
  expect_true("rt" %in% names(result))
  expect_length(result$item_idx, 1)
  expect_length(result$rt, 1)
})

test_that("accumulate_evidence_ddm_custom handles multiple items", {
  result <- accumulate_evidence_ddm_custom(
    A = c(1, 1.5, 2),
    V = c(0.1, 0.05, 0.03),
    Z = c(0, 0, 0),
    ndt = c(0.1, 0.2, 0.3),
    max_t = 100,
    dt = 0.01,
    max_reached = 3,
    noise_func = function(n, dt) rep(0.01, n)
  )

  expect_true("item_idx" %in% names(result))
  expect_true("rt" %in% names(result))
  expect_true(length(result$item_idx) <= 3)
})

test_that("accumulate_evidence_ddm_custom validates A parameter", {
  expect_error(
    accumulate_evidence_ddm_custom(
      A = c(1, 2),
      V = c(0.05),
      Z = c(0),
      ndt = c(0.2),
      max_t = 50,
      dt = 0.01,
      max_reached = 1,
      noise_func = function(n, dt) rep(0.01, n)
    ),
    "Length of A must be"
  )
})

test_that("accumulate_evidence_ddm_custom validates V parameter", {
  expect_error(
    accumulate_evidence_ddm_custom(
      A = c(1),
      V = c(0.05, 0.1),
      Z = c(0),
      ndt = c(0.2),
      max_t = 50,
      dt = 0.01,
      max_reached = 1,
      noise_func = function(n, dt) rep(0.01, n)
    ),
    "Length of ndt must be equal"
  )
})

test_that("accumulate_evidence_ddm_custom validates ndt parameter", {
  expect_error(
    accumulate_evidence_ddm_custom(
      A = c(1),
      V = c(0.05),
      Z = c(0),
      ndt = c(0.2, 0.3),
      max_t = 50,
      dt = 0.01,
      max_reached = 1,
      noise_func = function(n, dt) rep(0.01, n)
    ),
    "Length of ndt must be equal"
  )
})

test_that("accumulate_evidence_ddm_custom validates Z parameter", {
  expect_error(
    accumulate_evidence_ddm_custom(
      A = c(1),
      V = c(0.05),
      Z = c(0, 0.1),
      ndt = c(0.2),
      max_t = 50,
      dt = 0.01,
      max_reached = 1,
      noise_func = function(n, dt) rep(0.01, n)
    ),
    "Length of Z must be equal"
  )
})

test_that("accumulate_evidence_ddm_custom handles timeout correctly", {
  result <- accumulate_evidence_ddm_custom(
    A = c(100),  # Very high threshold
    V = c(0.01), # Very low drift
    Z = c(0),
    ndt = c(0),
    max_t = 1,   # Short timeout
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rep(0.001, n)
  )

  expect_length(result$item_idx, 0)
  expect_length(result$rt, 0)
})

test_that("accumulate_evidence_ddm_custom respects max_reached limit", {
  result <- accumulate_evidence_ddm_custom(
    A = c(0.5, 0.5, 0.5),
    V = c(0.1, 0.1, 0.1),
    Z = c(0, 0, 0),
    ndt = c(0, 0, 0),
    max_t = 50,
    dt = 0.01,
    max_reached = 2,
    noise_func = function(n, dt) rep(0.01, n)
  )

  expect_true(length(result$item_idx) <= 2)
})

test_that("accumulate_evidence_ddm_custom returns 1-based indices", {
  result <- accumulate_evidence_ddm_custom(
    A = c(0.5),
    V = c(0.1),
    Z = c(0),
    ndt = c(0),
    max_t = 50,
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rep(0.01, n)
  )

  if (length(result$item_idx) > 0) {
    expect_true(all(result$item_idx >= 1))
  }
})

test_that("accumulate_evidence_ddm_custom reaction times include ndt", {
  ndt_value <- 0.5
  result <- accumulate_evidence_ddm_custom(
    A = c(0.5),
    V = c(0.2),
    Z = c(0),
    ndt = c(ndt_value),
    max_t = 50,
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rep(0.01, n)
  )

  if (length(result$rt) > 0) {
    expect_true(all(result$rt >= ndt_value))
  }
})

test_that("accumulate_evidence_ddm_custom works with starting point Z", {
  result <- accumulate_evidence_ddm_custom(
    A = c(1),
    V = c(0.05),
    Z = c(0.5),  # Start halfway
    ndt = c(0),
    max_t = 50,
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rep(0.01, n)
  )

  expect_true("item_idx" %in% names(result))
  expect_true("rt" %in% names(result))
})

test_that("accumulate_evidence_ddm_custom alternating noise behavior", {
  # Test that the model produces results (the alternating behavior is internal)
  result <- accumulate_evidence_ddm_custom(
    A = c(1),
    V = c(0.05),
    Z = c(0),
    ndt = c(0),
    max_t = 100,
    dt = 0.01,
    max_reached = 1,
    noise_func = function(n, dt) rnorm(n, mean = 0, sd = 0.05)
  )

  # Should eventually reach threshold with positive drift
  expect_true(length(result$item_idx) > 0 || length(result$rt) > 0)
})
