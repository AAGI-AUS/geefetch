# test-auth.R — Tests for authentication utilities

test_that("gee_status() returns expected structure", {
  # Reset token state
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  result <- gee_status()
  expect_type(result, "list")
  expect_named(
    result,
    c(
      "authenticated",
      "project",
      "rgee_available",
      "cache_dir",
      "cache_size",
      "n_datasets"
    )
  )
  expect_false(result$authenticated)
  expect_type(result$project, "character")
  expect_type(result$rgee_available, "logical")
  expect_type(result$cache_size, "double")
  expect_true(is.integer(result$n_datasets) || is.numeric(result$n_datasets))
})

test_that(".check_gee_auth aborts when not authenticated", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(.check_gee_auth("rest"), "Not authenticated")
})

test_that(".check_gee_auth passes when token exists", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake_token_for_test"
  withr::defer(.geefetch_env$token <- old_token)

  expect_silent(.check_gee_auth("rest"))
})

test_that(".gee_project returns default project", {
  old_project <- .geefetch_env$project
  .geefetch_env$project <- NULL
  withr::defer(.geefetch_env$project <- old_project)

  expect_identical(.gee_project(), "earthengine-legacy")
})

test_that("gee_auth rejects nonexistent service account file", {
  expect_error(
    gee_auth(path = "/nonexistent/path/key.json"),
    "not found"
  )
})

test_that("gee_auth warns, and does not error, when no project is given", {
  # The fallback message names the default project. Interpolating a
  # dot-prefixed object directly ({.GEE_DEFAULT_PROJECT}) is read by cli as a
  # style, not a value, and aborts the call the warning was meant to soften.
  local_mocked_bindings(
    token_fetch = function(...) "fake_token_for_test",
    .package = "gargle"
  )
  old_token <- .geefetch_env$token
  old_project <- .geefetch_env$project
  withr::defer({
    .geefetch_env$token <- old_token
    .geefetch_env$project <- old_project
  })
  withr::local_options(list(geefetch.project = NULL))

  expect_warning(
    gee_auth(email = "test@test.com"),
    "falling back to"
  )
  expect_identical(.geefetch_env$project, .GEE_DEFAULT_PROJECT)
})

test_that("gee_setup runs without error", {
  expect_no_error(gee_setup())
})
