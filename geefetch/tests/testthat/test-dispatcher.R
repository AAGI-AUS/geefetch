# test-dispatcher.R — Tests for read_gee() dispatcher routing and aliases

test_that("read_gee requires authentication", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_gee(
      "modis_ndvi",
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34)
    ),
    "Not authenticated"
  )
})

test_that("read_gee validates dataset_id", {
  # Set a fake token so auth doesn't block us
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_gee("nonexistent_dataset"),
    "not recognised"
  )
})

test_that("read_gee validates date for time-series datasets", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_gee("modis_ndvi"),
    "requires a.*date"
  )
})

test_that("read_gee does not require date for static datasets", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  # This region exceeds 2048x2048 pixels at SRTM's native 30m scale, so
  # .build_grid() warns about resampling before the REST pipeline fails.
  # Should fail somewhere in the REST pipeline, but NOT on "requires a date"
  expect_warning(
    err <- tryCatch(
      read_gee("srtm_elevation", region = terra::ext(138, 140, -36, -34)),
      error = function(e) conditionMessage(e)
    ),
    regexp = "exceeds 2048x2048 pixels"
  )
  expect_true(is.character(err))
  expect_false(grepl("requires a.*date", err))
})

test_that("read_gee routes Tier 2 datasets to handlers (not 'not implemented')", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  # SLGA is static, so no date needed — should fail on region/REST, not "not implemented"
  err <- tryCatch(
    read_gee("slga_cly", region = terra::ext(138, 140, -36, -34)),
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("not yet implemented", err))
})

test_that("read_gee routes to cache on repeated call", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  # Pre-populate cache
  cache_key <- list(
    backend = "rest",
    date = "2024-06-15",
    region = terra::ext(138, 140, -36, -34)
  )
  # A raster with real cell values, so the disk cache write succeeds and
  # this test exercises the cache-read path only (not the write-failure
  # fallback, which is covered in test-cache.R).
  fake_result <- terra::rast(nrows = 10, ncols = 10, vals = seq_len(100))
  .cache_set("modis_ndvi", cache_key, fake_result)
  withr::defer(.geefetch_env$mem_cache <- NULL)

  result <- read_gee(
    "modis_ndvi",
    date = "2024-06-15",
    region = terra::ext(138, 140, -36, -34),
    cache = TRUE
  )
  expect_s4_class(result, "SpatRaster")
})

# ---- Convenience alias routing ----

test_that("read_modis_ndvi delegates to read_gee", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  # Should hit auth check, proving it goes through read_gee
  expect_error(
    read_modis_ndvi(
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34)
    ),
    "Not authenticated"
  )
})

test_that("read_modis_lst delegates to read_gee", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_modis_lst(
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34)
    ),
    "Not authenticated"
  )
})

test_that("read_era5 delegates with variable routing", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_era5(
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34),
      variable = "temperature"
    ),
    "Not authenticated"
  )

  expect_error(
    read_era5(
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34),
      variable = "precipitation"
    ),
    "Not authenticated"
  )
})

test_that("read_chirps delegates to read_gee", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_chirps(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    "Not authenticated"
  )
})

test_that("read_srtm delegates without date", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_srtm(region = terra::ext(138, 140, -36, -34)),
    "Not authenticated"
  )
})

test_that("read_era5 validates variable argument", {
  expect_error(
    read_era5(
      date = "2024-06-15",
      region = terra::ext(138, 140, -36, -34),
      variable = "wind_speed"
    )
  )
})
