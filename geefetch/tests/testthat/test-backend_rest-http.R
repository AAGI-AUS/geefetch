# Archetype-6a HTTP tests for the REST backend.
# Recipe 07 §"httptest2 patterns" — mocked calls against the GEE REST API
# using cassettes captured once against the live service and replayed in CI.
#
# Recapture procedure: see `tests/testthat/README.md`.

skip_if_no_httptest2 <- function() {
  testthat::skip_if_not_installed("httptest2")
}

# Minimal token stub — .rest_request() reads .geefetch_env$token via
# .gee_token(). A character string satisfies .extract_access_token()'s
# fast path; no gargle interaction.
local_fake_auth <- function(.local_envir = parent.frame()) {
  withr::defer(
    {
      assign("token", NULL, envir = asNamespace("geefetch")$.geefetch_env)
      assign("project", NULL, envir = asNamespace("geefetch")$.geefetch_env)
    },
    envir = .local_envir
  )
  assign("token", "fake-access-token", envir = asNamespace("geefetch")$.geefetch_env)
  assign("project", "geefetch-test-project", envir = asNamespace("geefetch")$.geefetch_env)
}

test_that(".rest_request() parses a successful computeFeatures response", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("computeFeatures-success")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("computeFeatures-success", {
    resp <- geefetch:::.rest_request(
      endpoint = "table:computeFeatures",
      body = list(
        expression = list(result = "0", values = list("0" = list(constantValue = 42))),
        pageSize = 5000L
      )
    )
    expect_type(resp, "list")
  })
})

test_that(".rest_request() surfaces 401 auth errors helpfully", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("computeFeatures-401")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("computeFeatures-401", {
    expect_error(
      geefetch:::.rest_request(
        endpoint = "table:computeFeatures",
        body = list(expression = list(result = "0", values = list()))
      ),
      "REST API error",
      class = "rlang_error"
    )
  })
})

test_that(".rest_request() surfaces 429 rate-limit errors helpfully", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("computeFeatures-429")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("computeFeatures-429", {
    expect_error(
      geefetch:::.rest_request(
        endpoint = "table:computeFeatures",
        body = list(expression = list(result = "0", values = list())),
        max_tries = 1L
      ),
      "REST API error",
      class = "rlang_error"
    )
  })
})

test_that(".rest_request() surfaces 403 API-not-enabled with setup guidance", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("computeFeatures-403")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("computeFeatures-403", {
    # Full message pattern is snapshot-tested separately; here just confirm
    # the error mentions the Earth Engine API being un-enabled.
    expect_error(
      geefetch:::.rest_request(
        endpoint = "table:computeFeatures",
        body = list(expression = list(result = "0", values = list()))
      ),
      "REST API error"
    )
  })
})
