# test-live.R — live integration tests against the real GEE REST API.
#
# These never run by default and never run on CRAN. They are gated on three
# conditions: not on CRAN, GEEFETCH_LIVE == "1", and a non-empty
# GEEFETCH_PROJECT. setup.R leaves GEEFETCH_PROJECT (and NO_INTERNET) alone
# whenever GEEFETCH_LIVE == "1" so it survives into this file.
#
# Run with:
#   GEEFETCH_PROJECT=<your 12-digit GCP project number> \
#   GEEFETCH_EMAIL=<the matching Google account email> \
#   GEEFETCH_LIVE=1 Rscript -e 'devtools::test(filter = "live")'

skip_on_cran()
skip_if_not(
  identical(Sys.getenv("GEEFETCH_LIVE"), "1"),
  "set GEEFETCH_LIVE=1 to run the live GEE integration suite"
)
skip_if_not(
  nzchar(Sys.getenv("GEEFETCH_PROJECT")),
  "GEEFETCH_PROJECT not set"
)

#' Authenticate against the live GEE REST API using env-var credentials.
#'
#' Reads the GCP project number from `GEEFETCH_PROJECT` and the matching
#' Google account email from `GEEFETCH_EMAIL`. Neither is hard-coded here;
#' set them in the shell before running the suite, e.g.:
#'
#'   GEEFETCH_PROJECT=123456789012 GEEFETCH_EMAIL=you@gmail.com \
#'   GEEFETCH_LIVE=1 Rscript -e 'devtools::test(filter = "live")'
#'
#' @noRd
.live_auth <- function() {
  project <- Sys.getenv("GEEFETCH_PROJECT")
  email <- Sys.getenv("GEEFETCH_EMAIL", unset = "")
  if (!nzchar(email)) {
    skip("GEEFETCH_EMAIL not set; required to authenticate for live tests")
  }
  invisible(gee_auth(project = project, email = email))
}

test_that("SRTM point extraction returns a finite elevation", {
  .live_auth()

  dt <- collect_gee_data(
    lon = 145.0,
    lat = -30.0,
    date_range = c("2022-06-01", "2022-06-01"),
    datasets = "srtm_elevation",
    cache = FALSE,
    verbose = FALSE
  )

  expect_true(is.finite(dt$srtm_elevation[[1L]]))
})

test_that("SMAP soil moisture matches the live value and masks the dry point", {
  .live_auth()

  gee_register_dataset(
    name = "smap_sm_live_test",
    collection = "NASA/SMAP/SPL3SMP_E/005",
    bands = "soil_moisture_am",
    scale = 9000L,
    temporal = "daily",
    description = "SMAP L3 soil moisture (AM), live-test registration"
  )

  xy <- data.frame(
    lon = c(138.75, 145.0, 117.5),
    lat = c(-34.5, -30.0, -32.0)
  )
  dt <- collect_gee_data(
    xy = xy,
    date_range = c("2022-06-01", "2022-06-01"),
    datasets = "smap_sm_live_test",
    cache = FALSE,
    verbose = FALSE
  )

  expect_equal(
    dt$smap_sm_live_test[dt$lon == 145.0],
    0.1737,
    tolerance = 1e-3
  )
  expect_true(is.na(dt$smap_sm_live_test[dt$lon == 138.75]))
})

test_that("a raster read returns a SpatRaster with cells", {
  .live_auth()

  r <- read_gee(
    "srtm_elevation",
    region = terra::ext(144.9, 145.1, -30.1, -29.9),
    cache = FALSE
  )

  expect_s4_class(r, "SpatRaster")
  expect_gt(terra::ncell(r), 0L)
})

test_that("SLGA point extraction honours depth and stat", {
  .live_auth()
  xy <- data.frame(lon = c(138.6, 145.0), lat = c(-34.6, -30.0))
  top <- collect_gee_data(
    xy = xy, date_range = c("2022-06-01", "2022-06-01"),
    datasets = "slga_cly", cache = FALSE, verbose = FALSE
  )
  deep <- collect_gee_data(
    xy = xy, date_range = c("2022-06-01", "2022-06-01"),
    datasets = "slga_cly", depth = "30-60", stat = "ci_upper",
    cache = FALSE, verbose = FALSE
  )
  expect_true(all(is.finite(top$slga_cly)))
  expect_true(all(deep$slga_cly > top$slga_cly))
})

test_that("Sentinel-2 NDVI is computed on both routes and bounded", {
  .live_auth()
  r <- read_gee(
    "sentinel2_ndvi", date = "2023-01-05",
    region = terra::ext(138.55, 138.6, -34.6, -34.55),
    cache = FALSE, verbose = FALSE
  )
  v <- terra::values(r)
  expect_gt(sum(!is.na(v)), 0L)
  expect_true(all(v[!is.na(v)] >= -1 & v[!is.na(v)] <= 1))
  pts <- collect_gee_data(
    xy = data.frame(lon = 145, lat = -30),
    date_range = c("2023-01-05", "2023-01-05"),
    datasets = "sentinel2_ndvi", cache = FALSE, verbose = FALSE
  )
  expect_true(is.finite(pts$sentinel2_ndvi))
  expect_lte(abs(pts$sentinel2_ndvi), 1)
})
