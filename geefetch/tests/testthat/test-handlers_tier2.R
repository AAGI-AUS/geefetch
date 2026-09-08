# test-handlers_tier2.R — Tests for Tier 2/3 handlers

# ---- SLGA band name construction ----

test_that(".slga_depth_to_code maps correctly", {
  expect_identical(.slga_depth_to_code("0-5"), "000_005")
  expect_identical(.slga_depth_to_code("100-200"), "100_200")
  expect_identical(.slga_depth_to_code("30-60"), "030_060")
})

test_that(".slga_depth_to_code rejects invalid depth", {
  expect_error(.slga_depth_to_code("0-10"), "Invalid SLGA depth")
})

test_that(".slga_stat_to_code maps correctly", {
  expect_identical(.slga_stat_to_code("mean"), "EV")
  expect_identical(.slga_stat_to_code("ci_lower"), "05")
  expect_identical(.slga_stat_to_code("ci_upper"), "95")
})

test_that(".slga_stat_to_code rejects invalid stat", {
  expect_error(.slga_stat_to_code("median"), "Invalid SLGA stat")
})

test_that("SLGA band name construction is correct", {
  depth <- .slga_depth_to_code("15-30")
  stat <- .slga_stat_to_code("mean")
  band <- paste0("CLY", "_", depth, "_", stat)
  expect_identical(band, "CLY_015_030_EV")
})

test_that("read_slga routes through dispatcher", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_slga(
      region = terra::ext(138, 140, -36, -34),
      collection = "PHC",
      depth = "30-60"
    ),
    "Not authenticated"
  )
})

test_that("read_slga validates collection argument", {
  expect_error(
    read_slga(region = terra::ext(138, 140, -36, -34), collection = "INVALID")
  )
})

test_that(".ee_mask_landsat_qa builds correct expression", {
  img <- .ee_load_image("TEST")
  masked <- .ee_mask_landsat_qa(img)
  inv <- masked$functionInvocationValue
  expect_identical(inv$functionName, "Image.updateMask")
})

test_that("read_sentinel2 routes through dispatcher", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_sentinel2(
      date = "2024-06-15",
      region = terra::ext(138, 139, -35, -34)
    ),
    "Not authenticated"
  )
})

test_that("read_landsat routes through dispatcher", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_landsat(date = "2024-06-15", region = terra::ext(138, 140, -36, -34)),
    "Not authenticated"
  )
})

# ---- Generic handler / Tier 3 datasets ----

test_that("WorldClim routes through generic handler", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_worldclim(region = terra::ext(138, 140, -36, -34)),
    "Not authenticated"
  )
})

test_that("WorldClim with variable argument doesn't error on validation", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_worldclim(region = terra::ext(138, 140, -36, -34), variable = "bio12"),
    "Not authenticated"
  )
})

test_that("OpenLandMap datasets resolve correctly", {
  expect_identical(.gee_resolve_id("openlandmap_soc"), "openlandmap_soc")
  expect_identical(.gee_resolve_id("OPENLANDMAP_CLAY"), "openlandmap_clay")
  expect_identical(.gee_resolve_id("OPENLANDMAP_PH"), "openlandmap_ph")
})

test_that("OpenLandMap routes through generic handler", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  expect_error(
    read_gee("openlandmap_soc", region = terra::ext(138, 140, -36, -34)),
    "Not authenticated"
  )
})

test_that("user-registered dataset routes through generic handler", {
  withr::defer(.geefetch_env$user_meta <- NULL)

  expect_message(
    gee_register_dataset(
      name = "test_generic",
      collection = "TEST/COLLECTION",
      bands = "band1",
      scale = 100L,
      temporal = "static",
      description = "Test"
    ),
    "Registered"
  )

  old_token <- .geefetch_env$token
  .geefetch_env$token <- NULL
  withr::defer(.geefetch_env$token <- old_token)

  # Should hit auth check, not "not implemented"
  expect_error(
    read_gee("test_generic", region = terra::ext(0, 1, 0, 1)),
    "Not authenticated"
  )
})

test_that("Tier 2 datasets no longer give 'not implemented' error", {
  old_token <- .geefetch_env$token
  .geefetch_env$token <- "fake"
  withr::defer(.geefetch_env$token <- old_token)

  # SLGA should attempt extraction, not say "not implemented"
  err <- tryCatch(
    read_gee("slga_cly", region = terra::ext(138, 140, -36, -34)),
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("not yet implemented", err, fixed = TRUE))
})

# ---- gee_datasets() updated count ----

test_that("gee_datasets() includes Tier 3 datasets", {
  dt <- gee_datasets()
  expect_true("worldclim_bio" %in% dt$dataset)
  expect_true("openlandmap_soc" %in% dt$dataset)
  expect_true("openlandmap_clay" %in% dt$dataset)
  expect_gte(nrow(dt), 18L) # 6 T1 + 9 T2 + 4 T3 = 19
})
