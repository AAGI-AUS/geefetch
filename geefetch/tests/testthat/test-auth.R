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
  expect_true(is.character(result$project))
  expect_true(is.logical(result$rgee_available))
  expect_true(is.numeric(result$cache_size))
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

  expect_equal(.gee_project(), "earthengine-legacy")
})

test_that("gee_auth rejects nonexistent service account file", {
  expect_error(
    gee_auth(path = "/nonexistent/path/key.json"),
    "not found"
  )
})

test_that("gee_setup runs without error", {
  expect_no_error(gee_setup())
})
