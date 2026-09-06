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
  assign("project", "ee-test", envir = asNamespace("geefetch")$.geefetch_env)
}

test_that(".rest_request() parses a successful computeFeatures response", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("cf-ok")) || nzchar(Sys.getenv("RPKG_RECAPTURE")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("cf-ok", {
    # A bare `constantValue` expression is rejected live with "Expression does
    # not compute to a table" (HTTP 400) -- computeFeatures requires the
    # expression to actually evaluate to a FeatureCollection. Use the same
    # Collection-of-Feature invocation `.ee_feature_collection()` builds for
    # real point extraction (grounded against the live API 2026-09-06).
    coords <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.6)
    resp <- geefetch:::.rest_request(
      endpoint = "table:computeFeatures",
      body = list(
        expression = geefetch:::.ee_expression(
          geefetch:::.ee_feature_collection(coords)
        ),
        pageSize = 5000L
      )
    )
    expect_type(resp, "list")
    expect_identical(resp$type, "FeatureCollection")
    expect_identical(resp$features[[1L]]$properties$point_id, 1L)
  })
})

test_that(".rest_request() surfaces 401 auth errors helpfully", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("cf-401")) || nzchar(Sys.getenv("RPKG_RECAPTURE")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("cf-401", {
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
    dir.exists(test_path("cf-429")) || nzchar(Sys.getenv("RPKG_RECAPTURE")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("cf-429", {
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
    dir.exists(test_path("cf-403")) || nzchar(Sys.getenv("RPKG_RECAPTURE")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  httptest2::with_mock_dir("cf-403", {
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

test_that(".rest_extract_batch_points() aligns values by point_id when the service drops masked points", {
  skip_if_no_httptest2()
  skip_if_not(
    dir.exists(test_path("cf-masked")) || nzchar(Sys.getenv("RPKG_RECAPTURE")),
    "HTTP cassette missing; run `RPKG_RECAPTURE=1 devtools::test(filter = 'backend_rest-http')` to capture."
  )
  local_fake_auth()

  # Recorded live (2026-09-06) against NASA/SMAP/SPL3SMP_E/005 soil_moisture_am
  # on 2022-06-01 for 3 points; the service replies with a single feature
  # (point_id 2) because the pixel at points 1 and 3 is masked (dry / no
  # retrieval) on that date -- `.rest_extract_batch_points()` must place that
  # one value at index 2 and NA elsewhere, never assume positional order.
  smap_meta <- list(
    collection = "NASA/SMAP/SPL3SMP_E/005",
    bands = "soil_moisture_am",
    scale = 9000L,
    temporal = "daily",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0
  )
  coords <- data.table::data.table(
    point_id = 1:3,
    lon = c(138.75, 145.0, 117.5),
    lat = c(-34.5, -30.0, -32.0)
  )

  httptest2::with_mock_dir("cf-masked", {
    vals <- geefetch:::.rest_extract_batch_points(
      meta = smap_meta,
      date = as.Date("2022-06-01"),
      coords = coords,
      max_tries = 3L,
      initial_delay = 1
    )

    expect_length(vals, 3L)
    expect_true(is.na(vals[1L]))
    expect_equal(vals[2L], 0.1736955, tolerance = 1e-6)
    expect_true(is.na(vals[3L]))
  })
})
