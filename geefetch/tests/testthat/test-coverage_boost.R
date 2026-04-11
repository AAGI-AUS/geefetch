# test-coverage_boost.R — Additional tests to improve coverage
# Targets uncovered paths in auth.R, utils.R, cache.R, handlers.R,
# backend_rest.R, collect_gee_data.R, qa_masking.R

# ---- auth.R coverage ----

test_that("gee_auth aborts on failed token fetch (NULL result)", {
  # Mock gargle to return NULL
  local_mocked_bindings(
    token_fetch = function(...) NULL,
    .package = "gargle"
  )
  expect_error(gee_auth(email = "test@test.com"), "authentication failed")
})

test_that("gee_status reports rgee as not available when missing", {
  local_mocked_bindings(
    is_installed = function(pkg, ...) {
      if (pkg == "rgee") FALSE else TRUE
    },
    .package = "rlang"
  )
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  result <- gee_status()
  expect_false(result$rgee_available)
})

test_that("gee_status reports cache size when cache exists", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  writeLines("test", file.path(tmp, "test.rds"))

  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  result <- gee_status()
  expect_true(result$cache_size > 0)
  expect_true(result$authenticated)
})

test_that(".gee_project uses option when set", {
  withr::local_options(list(geefetch.project = "my-custom-project"))
  old_project <- .geefetch_env$project
  .geefetch_env$project <- NULL
  withr::defer(.geefetch_env$project <- old_project)

  expect_equal(.gee_project(), "my-custom-project")
})

# ---- utils.R coverage ----

test_that(".validate_date checks dataset end date", {
  # SRTM has date_end = "2000-02-22"
  expect_error(
    .validate_date("2024-01-01", dataset_id = "srtm_elevation"),
    "after"
  )
})

test_that(".validate_region transforms non-WGS84 sf", {
  skip_if_not_installed("sf")
  # Create a polygon in UTM zone 54S
  poly_utm <- sf::st_sfc(
    sf::st_polygon(list(cbind(
      c(500000, 600000, 600000, 500000, 500000),
      c(6100000, 6100000, 6200000, 6200000, 6100000)
    ))),
    crs = 32754
  )
  result <- .validate_region(poly_utm)
  expect_equal(sf::st_crs(result)$epsg, 4326L)
})

test_that(".parse_coordinates transforms non-WGS84 sf points", {
  skip_if_not_installed("sf")
  pts_utm <- sf::st_as_sf(
    data.frame(x = 500000, y = 6100000),
    coords = c("x", "y"), crs = 32754
  )
  dt <- .parse_coordinates(xy = pts_utm)
  expect_true(dt$lon[1] > 100 && dt$lon[1] < 180)
  expect_true(dt$lat[1] < 0)
})

test_that(".parse_coordinates rejects non-POINT sf", {
  skip_if_not_installed("sf")
  line <- sf::st_sfc(
    sf::st_linestring(cbind(c(0, 1), c(0, 1))),
    crs = 4326
  )
  line_sf <- sf::st_sf(geometry = line)
  expect_error(.parse_coordinates(xy = line_sf), "POINT")
})

test_that(".gee_validate_args validates SLGA stat", {
  expect_error(
    .gee_validate_args("slga_cly", list(stat = "median")),
    "Invalid.*stat"
  )
})

# ---- cache.R coverage ----

test_that("cache uses RDS when fst not available", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  .geefetch_env$mem_cache <- NULL

  local_mocked_bindings(
    is_installed = function(pkg, ...) {
      if (pkg == "fst") FALSE else TRUE
    },
    .package = "rlang"
  )

  .cache_set("test_rds", list(a = 1), data.frame(x = 1:3))
  .geefetch_env$mem_cache <- NULL

  # Should read from RDS
  result <- .cache_get("test_rds", list(a = 1))
  expect_equal(nrow(result), 3L)
})

test_that(".cache_set warns on disk write failure", {
  # Use a non-writable directory
  withr::local_options(list(geefetch.cache_dir = "/nonexistent/path"))
  .geefetch_env$mem_cache <- NULL

  expect_warning(
    .cache_set("fail_test", list(a = 1), data.frame(x = 1)),
    "Failed to write"
  )
})

test_that("gee_clear_cache handles empty cache dir", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  n <- gee_clear_cache()
  expect_equal(n, 0L)
})

test_that("gee_clear_cache handles non-existent dir", {
  withr::local_options(list(geefetch.cache_dir = "/nonexistent/dir"))
  n <- gee_clear_cache()
  expect_equal(n, 0L)
})

# ---- qa_masking.R coverage ----

test_that(".ee_mask_modis_vi builds correct structure", {
  img <- .ee_load_image("TEST")
  masked <- .ee_mask_modis_vi(img)
  inv <- masked$functionInvocationValue
  expect_equal(inv$functionName, "Image.updateMask")
  # Check that the mask uses lte comparison
  mask_inv <- inv$arguments$mask$functionInvocationValue
  expect_equal(mask_inv$functionName, "Image.lte")
})

test_that(".ee_mask_modis_lst builds correct structure", {
  img <- .ee_load_image("TEST")
  masked <- .ee_mask_modis_lst(img)
  inv <- masked$functionInvocationValue
  expect_equal(inv$functionName, "Image.updateMask")
})

test_that(".ee_mask_s2_scl builds correct OR chain", {
  img <- .ee_load_image("TEST")
  masked <- .ee_mask_s2_scl(img)
  inv <- masked$functionInvocationValue
  expect_equal(inv$functionName, "Image.updateMask")
  # The mask should be an OR chain
  mask_inv <- inv$arguments$mask$functionInvocationValue
  expect_equal(mask_inv$functionName, "Image.Or")
})

# ---- handlers.R coverage (mocked) ----

test_that(".read_gee_modis_ndvi builds correct expression", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  # Mock the REST call to return a fake raster
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 10, ncols = 10, vals = runif(100))
    }
  )

  result <- .read_gee_modis_ndvi(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_era5_temp builds correct expression", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 10, ncols = 10, vals = runif(100, 10, 30))
    }
  )

  result <- .read_gee_era5_temp(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_srtm builds correct expression", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(...) {
      terra::rast(nrows = 10, ncols = 10, vals = runif(100, 0, 500))
    }
  )

  result <- .read_gee_srtm(
    dots = list(region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_slga builds correct band name", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(expr, region, meta, bands, ...) {
      # Verify the band name is correctly constructed
      expect_equal(bands, "PHC_030_060_95")
      terra::rast(nrows = 10, ncols = 10, vals = runif(100, 4, 9))
    }
  )

  result <- .read_gee_slga(
    dots = list(region = terra::ext(138, 140, -36, -34),
                depth = "30-60", stat = "ci_upper"),
    backend = "rest", max_tries = 1L, initial_delay = 0,
    attribute = "PHC"
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_sentinel2 applies SCL masking and computes NDVI", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(expr, ...) {
      # The expression should be a divide (NDVI computation)
      expect_equal(expr$functionInvocationValue$functionName, "Image.divide")
      terra::rast(nrows = 10, ncols = 10, vals = runif(100, -1, 1))
    }
  )

  result <- .read_gee_sentinel2(
    dots = list(date = "2024-06-15", region = terra::ext(138, 139, -35, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_landsat applies QA masking and computes NDVI", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(expr, ...) {
      # Should be divide (NDVI)
      expect_equal(expr$functionInvocationValue$functionName, "Image.divide")
      terra::rast(nrows = 10, ncols = 10, vals = runif(100, -1, 1))
    }
  )

  result <- .read_gee_landsat(
    dots = list(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".read_gee_generic works for worldclim with variable override", {
  local_mocked_bindings(
    .rest_extract_raster_expr = function(expr, region, meta, bands, ...) {
      # Verify the band was overridden to bio12
      expect_equal(bands, "bio12")
      terra::rast(nrows = 10, ncols = 10, vals = runif(100))
    }
  )

  result <- .read_gee_generic(
    dots = list(region = terra::ext(138, 140, -36, -34), variable = "bio12"),
    did = "worldclim_bio",
    backend = "rest", max_tries = 1L, initial_delay = 0
  )
  expect_s4_class(result, "SpatRaster")
})

test_that(".rgee_extract aborts when rgee not installed", {
  local_mocked_bindings(
    is_installed = function(pkg, ...) FALSE,
    .package = "rlang"
  )
  expect_error(
    .rgee_extract(.GEE_META$modis_ndvi, NULL, NULL, 1L, 1),
    "rgee.*required"
  )
})

# ---- backend_rest.R coverage ----

test_that(".rest_request aborts when not authenticated", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(.rest_request("test/endpoint"), "Not authenticated")
})

test_that(".build_grid handles equatorial coordinates", {
  bbox <- c(xmin = 36, ymin = -2, xmax = 38, ymax = 0)
  grid <- .build_grid(bbox, scale = 1000L)
  expect_true(grid$dimensions$width > 0)
  expect_true(grid$dimensions$height > 0)
  expect_equal(grid$crsCode, "EPSG:4326")
})

test_that(".parse_features_to_dt handles empty input", {
  dt <- .parse_features_to_dt(list())
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that(".coords_to_geojson handles single point", {
  coords <- data.table::data.table(point_id = 1L, lon = 0, lat = 0)
  gj <- .coords_to_geojson(coords)
  expect_equal(length(gj$features), 1L)
})

# ---- collect_gee_data.R coverage ----

test_that(".rest_extract_single_point handles static datasets", {
  local_mocked_bindings(
    .rest_compute_features = function(...) {
      data.table::data.table(point_id = 1L, elevation = 350)
    }
  )

  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  val <- .rest_extract_single_point(
    meta = .GEE_META$srtm_elevation,
    date = NULL,
    pt_coords = pt,
    max_tries = 1L,
    initial_delay = 0
  )
  expect_equal(val, 350)
})

test_that(".rest_extract_single_point returns NA for empty response", {
  local_mocked_bindings(
    .rest_compute_features = function(...) data.table::data.table()
  )

  pt <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  val <- .rest_extract_single_point(
    meta = .GEE_META$era5_temp,
    date = as.Date("2024-01-01"),
    pt_coords = pt,
    max_tries = 1L,
    initial_delay = 0
  )
  expect_true(is.na(val))
})

test_that(".rest_extract_batch_points applies QA masking for MODIS", {
  local_mocked_bindings(
    .rest_compute_features = function(expression, ...) {
      # Verify the expression contains updateMask (QA masking)
      expr_json <- jsonlite::toJSON(expression, auto_unbox = TRUE)
      expect_true(grepl("updateMask", expr_json))
      data.table::data.table(point_id = 1L, NDVI = 0.65)
    }
  )

  coords <- data.table::data.table(point_id = 1L, lon = 138.6, lat = -34.9)
  vals <- .rest_extract_batch_points(
    meta = .GEE_META$modis_ndvi,
    date = as.Date("2024-06-15"),
    coords = coords,
    max_tries = 1L,
    initial_delay = 0
  )
  expect_equal(vals, 0.65)
})

test_that(".rest_extract_batch_points handles multi-point response", {
  local_mocked_bindings(
    .rest_compute_features = function(...) {
      data.table::data.table(
        point_id = 1:3,
        elevation = c(100, 200, 300)
      )
    }
  )

  coords <- data.table::data.table(
    point_id = 1:3,
    lon = c(138, 139, 140),
    lat = c(-34, -35, -36)
  )
  vals <- .rest_extract_batch_points(
    meta = .GEE_META$srtm_elevation,
    date = NULL,
    coords = coords,
    max_tries = 1L,
    initial_delay = 0
  )
  expect_equal(vals, c(100, 200, 300))
})

test_that("collect_gee_data verbose mode prints info table", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  local_mocked_bindings(
    .safe_extract_points_batch = function(meta, date, coords, ...) {
      rep(1.0, nrow(coords))
    }
  )

  expect_message(
    collect_gee_data(
      lon = 138.6, lat = -34.9,
      date_range = c("2024-01-01", "2024-01-01"),
      datasets = "modis_ndvi",
      verbose = TRUE
    ),
    "collect_gee_data|Datasets|Estimated"
  )
})
