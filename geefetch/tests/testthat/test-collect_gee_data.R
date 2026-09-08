# test-collect_gee_data.R — Tests for batch extraction

# ---- Input validation ----

test_that("collect_gee_data requires datasets argument", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-01-01", "2024-01-05")
    ),
    "datasets.*must be"
  )
})

test_that("collect_gee_data validates coordinates", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      date_range = c("2024-01-01", "2024-01-05"),
      datasets = "modis_ndvi"
    ),
    "No coordinates"
  )
})

test_that("collect_gee_data validates date_range", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-12-31", "2024-01-01"),
      datasets = "modis_ndvi"
    ),
    "after end date"
  )
})

test_that("collect_gee_data validates dataset names", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-01-01", "2024-01-05"),
      datasets = c("modis_ndvi", "nonexistent")
    ),
    "not recognised"
  )
})

test_that("collect_gee_data requires authentication", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-01-01", "2024-01-05"),
      datasets = "modis_ndvi"
    ),
    "Not authenticated"
  )
})

test_that("collect_gee_data accepts sf input", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  skip_if_not_installed("sf")
  pts <- sf::st_as_sf(
    data.frame(lon = 138.6, lat = -34.9),
    coords = c("lon", "lat"),
    crs = 4326
  )
  expect_error(
    collect_gee_data(
      xy = pts,
      date_range = c("2024-01-01", "2024-01-02"),
      datasets = "modis_ndvi"
    ),
    "Not authenticated"
  )
})

test_that("collect_gee_data resolves aliases in datasets", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-01-01", "2024-01-02"),
      datasets = c("NDVI", "SRTM")
    ),
    "Not authenticated"
  )
})


# ---- Batch extraction with mocks ----

test_that(".safe_extract_points_batch returns NA vector on error", {
  local_mocked_bindings(
    .rest_extract_batch_points = function(...) stop("simulated failure")
  )

  coords <- data.table::data.table(
    point_id = 1:2,
    lon = c(138.6, 149.1),
    lat = c(-34.9, -35.3)
  )

  expect_warning(
    vals <- .safe_extract_points_batch(
      meta = .GEE_META$era5_temp,
      date = as.Date("2024-01-01"),
      coords = coords,
      did = "era5_temp",
      backend = "rest",
      cache = FALSE,
      max_tries = 1L,
      initial_delay = 0
    ),
    "Batch extraction failed"
  )
  expect_length(vals, 2L)
  expect_true(all(is.na(vals)))
})

test_that("collect_gee_data with mock produces correct output shape", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_points_batch = function(meta, date, coords, did, ...) {
      n <- nrow(coords)
      switch(
        did,
        modis_ndvi = rep(0.65, n),
        srtm_elevation = rep(200.0, n),
        rep(NA_real_, n)
      )
    }
  )

  dt <- collect_gee_data(
    lon = c(138.6, 149.1),
    lat = c(-34.9, -35.3),
    date_range = c("2024-01-01", "2024-01-03"),
    datasets = c("modis_ndvi", "srtm_elevation"),
    verbose = FALSE
  )

  expect_s3_class(dt, "data.table")
  # 2 locations x 3 dates = 6 rows
  expect_identical(nrow(dt), 6L)
  expect_true(all(
    c("point_id", "lon", "lat", "date", "modis_ndvi", "srtm_elevation") %in%
      names(dt)
  ))
  expect_equal(unique(dt$modis_ndvi), 0.65)
  expect_equal(unique(dt$srtm_elevation), 200.0)
  expect_identical(sort(unique(dt$point_id)), c(1L, 2L))
})

test_that("collect_gee_data na.rm removes all-NA rows", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_points_batch = function(meta, date, coords, did, ...) {
      n <- nrow(coords)
      if (!is.null(date) && date == as.Date("2024-01-02")) {
        rep(NA_real_, n)
      } else {
        rep(0.5, n)
      }
    }
  )

  dt <- collect_gee_data(
    lon = 138.6,
    lat = -34.9,
    date_range = c("2024-01-01", "2024-01-03"),
    datasets = "modis_ndvi",
    na.rm = TRUE,
    verbose = FALSE
  )

  expect_identical(nrow(dt), 2L)
  expect_false(as.Date("2024-01-02") %in% dt$date)
})

test_that("collect_gee_data column order is correct", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_points_batch = function(meta, date, coords, did, ...) {
      rep(1.0, nrow(coords))
    }
  )

  dt <- collect_gee_data(
    lon = 138.6,
    lat = -34.9,
    date_range = c("2024-01-01", "2024-01-01"),
    datasets = c("era5_temp", "modis_ndvi"),
    verbose = FALSE
  )

  expect_identical(names(dt)[1:4], c("point_id", "lon", "lat", "date"))
})

test_that("collect_gee_data verbose mode prints info", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_points_batch = function(...) 1.0
  )

  expect_message(
    collect_gee_data(
      lon = 138.6,
      lat = -34.9,
      date_range = c("2024-01-01", "2024-01-01"),
      datasets = "modis_ndvi",
      verbose = TRUE
    ),
    "collect_gee_data|Datasets|Estimated"
  )
})


# ---- .print_collection_info ----

test_that(".print_collection_info runs without error", {
  coords <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  dates <- as.Date(c("2024-01-01", "2024-01-05"))
  resolved <- c("modis_ndvi", "srtm_elevation")
  is_static <- c(FALSE, TRUE)

  expect_no_error(
    .print_collection_info(
      coords,
      dates,
      resolved,
      is_static,
      .gee_combined_meta()
    )
  )
})
