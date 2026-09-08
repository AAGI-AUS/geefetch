# test-validation.R — Tests for input validation and parsing utilities

# ---- Date validation ----

test_that(".validate_date parses valid date formats", {
  expect_equal(.validate_date("2024-06-15"), as.Date("2024-06-15"))
  expect_equal(.validate_date(as.Date("2024-06-15")), as.Date("2024-06-15"))
})

test_that(".validate_date rejects invalid dates", {
  expect_error(.validate_date("not-a-date"), "Cannot parse")
  expect_error(.validate_date(NULL), "required")
  expect_error(.validate_date(NA), "Cannot parse")
})

test_that(".validate_date checks dataset date range", {
  # MODIS NDVI starts 2000-02-18
  expect_error(
    .validate_date("1999-01-01", dataset_id = "modis_ndvi"),
    "before"
  )
  # Valid date should pass
  expect_equal(
    .validate_date("2024-06-15", dataset_id = "modis_ndvi"),
    as.Date("2024-06-15")
  )
})

# ---- Date range parsing ----

test_that(".parse_date_range expands length-2 to sequence", {
  dates <- .parse_date_range(c("2024-01-01", "2024-01-05"))
  expect_length(dates, 5L)
  expect_equal(dates[1L], as.Date("2024-01-01"))
  expect_equal(dates[5L], as.Date("2024-01-05"))
})

test_that(".parse_date_range passes through explicit vectors", {
  explicit <- as.Date(c("2024-01-01", "2024-03-15", "2024-06-01"))
  result <- .parse_date_range(explicit)
  expect_equal(result, sort(explicit))
})

test_that(".parse_date_range rejects reversed range", {
  expect_error(
    .parse_date_range(c("2024-12-31", "2024-01-01")),
    "after end date"
  )
})

test_that(".parse_date_range rejects empty input", {
  expect_error(.parse_date_range(NULL), "must not be empty")
  expect_error(.parse_date_range(character(0L)), "must not be empty")
})

# ---- Coordinate validation ----

test_that(".validate_single_coord accepts valid coordinates", {
  expect_equal(.validate_single_coord(138.6, "lon"), 138.6)
  expect_equal(.validate_single_coord(-34.9, "lat"), -34.9)
  expect_equal(.validate_single_coord(0, "lon"), 0)
  expect_equal(.validate_single_coord(0, "lat"), 0)
})

test_that(".validate_single_coord rejects out-of-range", {
  expect_error(.validate_single_coord(181, "lon"), "out of range")
  expect_error(.validate_single_coord(-181, "lon"), "out of range")
  expect_error(.validate_single_coord(91, "lat"), "out of range")
  expect_error(.validate_single_coord(-91, "lat"), "out of range")
})

test_that(".validate_single_coord rejects non-numeric", {
  expect_error(.validate_single_coord("a", "lon"), "non-NA numeric")
  expect_error(.validate_single_coord(NA_real_, "lon"), "non-NA numeric")
  expect_error(.validate_single_coord(c(1, 2), "lon"), "non-NA numeric")
})

# ---- Coordinate parsing ----

test_that(".parse_coordinates works with lon/lat vectors", {
  dt <- .parse_coordinates(lon = c(138.6, 149.1), lat = c(-34.9, -35.3))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("point_id", "lon", "lat") %in% names(dt)))
  expect_equal(dt$lon, c(138.6, 149.1))
})

test_that(".parse_coordinates works with data.frame xy", {
  df <- data.frame(lon = 138.6, lat = -34.9)
  dt <- .parse_coordinates(xy = df)
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$lon, 138.6)
})

test_that(".parse_coordinates works with x/y column names", {
  df <- data.frame(x = 138.6, y = -34.9)
  dt <- .parse_coordinates(xy = df)
  expect_equal(dt$lon, 138.6)
  expect_equal(dt$lat, -34.9)
})

test_that(".parse_coordinates works with longitude/latitude column names", {
  df <- data.frame(longitude = 138.6, latitude = -34.9)
  dt <- .parse_coordinates(xy = df)
  expect_equal(dt$lon, 138.6)
})

test_that(".parse_coordinates works with sf POINT objects", {
  skip_if_not_installed("sf")
  pts <- sf::st_as_sf(
    data.frame(lon = c(138.6, 149.1), lat = c(-34.9, -35.3)),
    coords = c("lon", "lat"),
    crs = 4326
  )
  dt <- .parse_coordinates(xy = pts)
  expect_equal(nrow(dt), 2L)
  expect_equal(dt$lon[1L], 138.6, tolerance = 0.001)
})

test_that(".parse_coordinates rejects mismatched lengths", {
  expect_error(
    .parse_coordinates(lon = c(1, 2), lat = 1),
    "same length"
  )
})

test_that(".parse_coordinates rejects missing coordinates", {
  expect_error(.parse_coordinates(), "No coordinates")
})

test_that(".parse_coordinates rejects data.frame without recognisable columns", {
  df <- data.frame(a = 1, b = 2)
  expect_error(.parse_coordinates(xy = df), "must have columns")
})

# ---- Dataset validation ----

test_that(".validate_dataset accepts known datasets", {
  expect_invisible(.validate_dataset("modis_ndvi"))
  expect_invisible(.validate_dataset("srtm_elevation"))
})

test_that(".validate_dataset rejects unknown datasets", {
  expect_error(.validate_dataset("nonexistent"), "not recognised")
})

# ---- Region validation ----

test_that(".validate_region returns NULL for NULL input", {
  expect_null(.validate_region(NULL))
})

test_that(".validate_region converts SpatExtent", {
  skip_if_not_installed("terra")
  ext <- terra::ext(138, 140, -36, -34)
  result <- .validate_region(ext)
  expect_true(inherits(result, c("sf", "sfc")))
})

test_that(".validate_region rejects non-spatial objects", {
  expect_error(.validate_region(42), "must be an")
  expect_error(.validate_region("not spatial"), "must be an")
})

# ---- Dispatcher argument validation ----

test_that(".gee_validate_args requires date for time-series datasets", {
  expect_error(
    .gee_validate_args("modis_ndvi", list()),
    "requires a.*date"
  )
  # Static datasets should not require date
  expect_silent(.gee_validate_args("srtm_elevation", list()))
})

test_that(".gee_validate_args validates SLGA depth", {
  expect_error(
    .gee_validate_args("slga_cly", list(date = NULL, depth = "bad")),
    "Invalid.*depth"
  )
  expect_silent(
    .gee_validate_args("slga_cly", list(depth = "0-5"))
  )
})
