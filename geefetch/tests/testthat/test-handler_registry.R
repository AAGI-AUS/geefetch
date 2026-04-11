# test-handler_registry.R — Tests for alias resolution, metadata, and catalogue

test_that(".gee_resolve_id resolves normalised IDs directly", {
  expect_equal(.gee_resolve_id("modis_ndvi"), "modis_ndvi")
  expect_equal(.gee_resolve_id("srtm_elevation"), "srtm_elevation")
  expect_equal(.gee_resolve_id("era5_temp"), "era5_temp")
})

test_that(".gee_resolve_id resolves aliases (case-insensitive)", {
  expect_equal(.gee_resolve_id("MODIS_NDVI"), "modis_ndvi")
  expect_equal(.gee_resolve_id("NDVI"), "modis_ndvi")
  expect_equal(.gee_resolve_id("ndvi"), "modis_ndvi")
  expect_equal(.gee_resolve_id("SRTM"), "srtm_elevation")
  expect_equal(.gee_resolve_id("elevation"), "srtm_elevation")
  expect_equal(.gee_resolve_id("CHIRPS"), "chirps_precip")
  expect_equal(.gee_resolve_id("LST"), "modis_lst")
})

test_that(".gee_resolve_id rejects invalid inputs", {
  expect_error(.gee_resolve_id("nonexistent_dataset"), "not recognised")
  expect_error(.gee_resolve_id(123), "single character string")
  expect_error(.gee_resolve_id(c("a", "b")), "single character string")
  expect_error(.gee_resolve_id(NULL), "single character string")
})

test_that(".GEE_META has required fields for all datasets", {
  required_fields <- c(
    "collection", "bands", "scale", "temporal",
    "scale_factor", "offset", "domain", "description"
  )
  for (nm in names(.GEE_META)) {
    meta <- .GEE_META[[nm]]
    for (field in required_fields) {
      expect_true(
        field %in% names(meta),
        info = paste0("Dataset '", nm, "' missing field '", field, "'")
      )
    }
  }
})

test_that(".GEE_META temporal values are valid", {
  valid_temporal <- c("daily", "8day", "16day", "monthly", "5day", "static")
  for (nm in names(.GEE_META)) {
    expect_true(
      .GEE_META[[nm]]$temporal %in% valid_temporal,
      info = paste0("Dataset '", nm, "' has invalid temporal: ", .GEE_META[[nm]]$temporal)
    )
  }
})

test_that("all .GEE_ALIASES point to valid dataset IDs", {
  for (alias_name in names(.GEE_ALIASES)) {
    target <- .GEE_ALIASES[[alias_name]]
    expect_true(
      target %in% names(.GEE_META),
      info = paste0("Alias '", alias_name, "' -> '", target, "' not in .GEE_META")
    )
  }
})

test_that("gee_datasets() returns a data.table with expected columns", {
  dt <- gee_datasets()
  expect_s3_class(dt, "data.table")
  expect_true(all(c("dataset", "collection", "domain", "resolution",
                     "temporal", "description") %in% names(dt)))
  expect_true(nrow(dt) >= length(.GEE_META))
})

test_that("gee_datasets() domain filter works", {
  dt_veg <- gee_datasets(domain = "Vegetation")
  expect_true(all(dt_veg$domain == "Vegetation"))
  expect_true(nrow(dt_veg) > 0L)

  dt_none <- gee_datasets(domain = "NonexistentDomain")
  expect_equal(nrow(dt_none), 0L)
})

test_that("gee_register_dataset() adds custom dataset to registry", {
  # Clean up after test
  withr::defer(.geefetch_env$user_meta <- NULL)

  expect_message(
    gee_register_dataset(
      name        = "test_custom",
      collection  = "TEST/COLLECTION",
      bands       = "band1",
      scale       = 100L,
      temporal    = "daily",
      description = "Test custom dataset"
    ),
    "Registered"
  )

  # Should be resolvable
  expect_equal(.gee_resolve_id("test_custom"), "test_custom")

  # Should appear in catalogue
  dt <- gee_datasets()
  expect_true("test_custom" %in% dt$dataset)
})

test_that("gee_register_dataset() rejects built-in name override", {
  expect_error(
    gee_register_dataset(
      name        = "modis_ndvi",
      collection  = "FAKE",
      bands       = "b1",
      scale       = 10L,
      temporal    = "daily",
      description = "Fake"
    ),
    "Cannot overwrite built-in"
  )
})

test_that("gee_register_dataset() validates temporal argument", {
  expect_error(
    gee_register_dataset(
      name        = "bad_temporal",
      collection  = "FAKE",
      bands       = "b1",
      scale       = 10L,
      temporal    = "weekly",
      description = "Bad"
    ),
    "weekly"
  )
})

test_that("SLGA metadata constants are consistent", {
  expect_equal(length(.SLGA_DEPTHS), 6L)
  expect_equal(length(.SLGA_DEPTH_LABELS), 6L)
  expect_equal(names(.SLGA_DEPTH_LABELS), .SLGA_DEPTHS)
  expect_equal(length(.SLGA_STATS), 3L)
  expect_true(all(.SLGA_ATTRIBUTES %in% c("CLY", "SND", "AWC", "SLT", "BDW", "PHC", "NTO")))
})
