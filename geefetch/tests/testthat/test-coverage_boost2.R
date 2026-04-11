# test-coverage_boost2.R — Final coverage push

# ---- auth.R: gee_setup prints all steps ----

test_that("gee_setup prints all 5 steps", {
  output <- capture.output(gee_setup(), type = "message")
  output_str <- paste(output, collapse = "\n")
  expect_true(grepl("Step 1", output_str))
  expect_true(grepl("Step 5", output_str))
  expect_true(grepl("gee_auth", output_str))
})

# ---- handlers.R: remaining handler paths ----

test_that(".read_gee_modis_lst builds and extracts", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 5, ncols = 5, vals = runif(25, 270, 310))
    }
  )
  result <- .read_gee_modis_lst(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_era5_precip builds and extracts", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 5, ncols = 5, vals = runif(25, 0, 20))
    }
  )
  result <- .read_gee_era5_precip(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_chirps builds and extracts", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 5, ncols = 5, vals = runif(25, 0, 50))
    }
  )
  result <- .read_gee_chirps(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

# ---- handlers.R: rgee backend abort ----

test_that("handler rgee backend aborts with message", {
  expect_error(
    .read_gee_modis_ndvi(
      dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
      backend = "rgee", max_tries = 1L, initial_delay = 0
    ),
    "rgee.*not yet implemented|rgee.*required"
  )
})

# ---- collect_gee_data.R: point extraction for time-series ----

test_that(".rest_extract_single_point handles time-series with band match", {
  local_mocked_bindings(
    .rest_compute_features = function(...) {
      data.table::data.table(point_id = 1L, precipitation = 12.5)
    }
  )
  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  val <- .rest_extract_single_point(
    meta = .GEE_META$chirps_precip,
    date = as.Date("2024-06-15"),
    pt_coords = pt,
    max_tries = 1L, initial_delay = 0
  )
  expect_equal(val, 12.5)
})

test_that(".rest_extract_single_point returns NA when band not in response", {
  local_mocked_bindings(
    .rest_compute_features = function(...) {
      data.table::data.table(point_id = 1L, wrong_band = 99)
    }
  )
  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  val <- .rest_extract_single_point(
    meta = .GEE_META$chirps_precip,
    date = as.Date("2024-06-15"),
    pt_coords = pt,
    max_tries = 1L, initial_delay = 0
  )
  expect_true(is.na(val))
})

# ---- read_gee.R: cache hit returns early ----

test_that("read_gee returns cached raster on hit", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)
  withr::defer(.geefetch_env$mem_cache <- NULL)

  fake_rast <- terra::rast(nrows = 5, ncols = 5, vals = 1:25)
  cache_key <- list(
    backend = "rest",
    date = "2024-01-01",
    region = terra::ext(138, 140, -36, -34)
  )
  .cache_set("era5_temp", cache_key, fake_rast)

  result <- read_gee("era5_temp",
                     date = "2024-01-01",
                     region = terra::ext(138, 140, -36, -34))
  expect_s4_class(result, "SpatRaster")
})

# ---- utils.R: edge cases ----

test_that(".validate_date handles POSIXct input", {
  dt <- .validate_date(as.POSIXct("2024-06-15", tz = "UTC"))
  expect_equal(dt, as.Date("2024-06-15"))
})

test_that(".parse_date_range returns sorted unique dates", {
  dates <- .parse_date_range(as.Date(c("2024-01-05", "2024-01-01", "2024-01-03", "2024-01-01")))
  expect_equal(length(dates), 3L)
  expect_equal(dates[1L], as.Date("2024-01-01"))
})

test_that(".validate_region handles sf with NA CRS", {
  skip_if_not_installed("sf")
  poly <- sf::st_sfc(sf::st_polygon(list(
    cbind(c(138, 140, 140, 138, 138), c(-36, -36, -34, -34, -36))
  )))
  # No CRS set — should still pass
  result <- .validate_region(poly)
  expect_true(inherits(result, c("sf", "sfc")))
})
