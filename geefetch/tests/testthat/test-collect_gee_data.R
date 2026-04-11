# test-collect_gee_data.R — Tests for batch extraction

# ---- Input validation ----

test_that("collect_gee_data requires datasets argument", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(lon = 138.6, lat = -34.9,
                     date_range = c("2024-01-01", "2024-01-05")),
    "datasets.*must be"
  )
})

test_that("collect_gee_data validates coordinates", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(date_range = c("2024-01-01", "2024-01-05"),
                     datasets = "modis_ndvi"),
    "No coordinates"
  )
})

test_that("collect_gee_data validates date_range", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(lon = 138.6, lat = -34.9,
                     date_range = c("2024-12-31", "2024-01-01"),
                     datasets = "modis_ndvi"),
    "after end date"
  )
})

test_that("collect_gee_data validates dataset names", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(lon = 138.6, lat = -34.9,
                     date_range = c("2024-01-01", "2024-01-05"),
                     datasets = c("modis_ndvi", "nonexistent")),
    "not recognised"
  )
})

test_that("collect_gee_data requires authentication", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    collect_gee_data(lon = 138.6, lat = -34.9,
                     date_range = c("2024-01-01", "2024-01-05"),
                     datasets = "modis_ndvi"),
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
    coords = c("lon", "lat"), crs = 4326
  )
  # Should fail on auth, not on coordinate parsing
  expect_error(
    collect_gee_data(xy = pts,
                     date_range = c("2024-01-01", "2024-01-02"),
                     datasets = "modis_ndvi"),
    "Not authenticated"
  )
})

test_that("collect_gee_data resolves aliases in datasets", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  # NDVI is an alias for modis_ndvi — should not fail on resolution
  expect_error(
    collect_gee_data(lon = 138.6, lat = -34.9,
                     date_range = c("2024-01-01", "2024-01-02"),
                     datasets = c("NDVI", "SRTM")),
    "Not authenticated"
  )
})


# ---- Internal helpers ----

test_that(".collect_single_location returns correct structure", {
  # Mock: override .safe_extract_point to return predictable values
  local_mocked_bindings(
    .safe_extract_point = function(meta, date, pt_coords, did, ...) {
      if (did == "srtm_elevation") return(350.0)
      if (did == "era5_temp") return(15.5 + as.numeric(date - as.Date("2024-01-01")))
      NA_real_
    }
  )

  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  dates <- as.Date(c("2024-01-01", "2024-01-02", "2024-01-03"))
  meta <- .gee_combined_meta()

  dt <- .collect_single_location(
    pt_coords       = pt,
    dates           = dates,
    ts_datasets     = "era5_temp",
    static_datasets = "srtm_elevation",
    combined_meta   = meta,
    backend         = "rest",
    cache           = FALSE,
    max_tries       = 1L,
    initial_delay   = 0
  )

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true(all(c("point_id", "lon", "lat", "date", "era5_temp",
                     "srtm_elevation") %in% names(dt)))

  # Static value replicated
  expect_equal(dt$srtm_elevation, c(350, 350, 350))

  # Time-series values differ per date
  expect_equal(dt$era5_temp[1], 15.5)
  expect_equal(dt$era5_temp[2], 16.5)
  expect_equal(dt$era5_temp[3], 17.5)
})

test_that(".safe_extract_point returns NA on error", {
  # Mock: force an error
  local_mocked_bindings(
    .rest_extract_single_point = function(...) stop("simulated failure")
  )

  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  meta <- .GEE_META$era5_temp

  expect_warning(
    val <- .safe_extract_point(
      meta = meta, date = as.Date("2024-01-01"),
      pt_coords = pt, did = "era5_temp",
      backend = "rest", cache = FALSE,
      max_tries = 1L, initial_delay = 0
    ),
    "Extraction failed"
  )
  expect_true(is.na(val))
})

test_that("collect_gee_data with mock produces correct output shape", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_point = function(meta, date, pt_coords, did, ...) {
      switch(did,
        modis_ndvi = 0.65,
        srtm_elevation = 200.0,
        NA_real_
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
  expect_equal(nrow(dt), 6L)
  # Expected columns
  expect_true(all(c("point_id", "lon", "lat", "date",
                     "modis_ndvi", "srtm_elevation") %in% names(dt)))
  # All NDVI values should be 0.65
  expect_equal(unique(dt$modis_ndvi), 0.65)
  # Static elevation replicated
  expect_equal(unique(dt$srtm_elevation), 200.0)
  # Correct point_ids
  expect_equal(sort(unique(dt$point_id)), c(1L, 2L))
})

test_that("collect_gee_data na.rm removes all-NA rows", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  call_count <- 0L
  local_mocked_bindings(
    .safe_extract_point = function(meta, date, pt_coords, did, ...) {
      call_count <<- call_count + 1L
      # Return NA for some dates
      if (!is.null(date) && date == as.Date("2024-01-02")) NA_real_ else 0.5
    }
  )

  dt <- collect_gee_data(
    lon = 138.6, lat = -34.9,
    date_range = c("2024-01-01", "2024-01-03"),
    datasets = "modis_ndvi",
    na.rm = TRUE,
    verbose = FALSE
  )

  # Row for 2024-01-02 should be removed (NA)
  expect_equal(nrow(dt), 2L)
  expect_false(as.Date("2024-01-02") %in% dt$date)
})

test_that("collect_gee_data column order is correct", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_point = function(...) 1.0
  )

  dt <- collect_gee_data(
    lon = 138.6, lat = -34.9,
    date_range = c("2024-01-01", "2024-01-01"),
    datasets = c("era5_temp", "modis_ndvi"),
    verbose = FALSE
  )

  # First four columns should be id cols
  expect_equal(names(dt)[1:4], c("point_id", "lon", "lat", "date"))
})


# ---- .print_collection_info ----

test_that(".print_collection_info runs without error", {
  coords <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  dates <- as.Date(c("2024-01-01", "2024-01-05"))
  resolved <- c("modis_ndvi", "srtm_elevation")
  is_static <- c(FALSE, TRUE)

  expect_no_error(
    .print_collection_info(coords, dates, resolved, is_static, .gee_combined_meta())
  )
})
