#' Read Landsat 9 NDVI from Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Computes NDVI from Landsat 9 OLI-2 Collection 2 Level-2 surface
#' reflectance (LANDSAT/LC09/C02/T1_L2) on Google Earth Engine.
#' Cloud, shadow, and snow pixels are masked using the QA_PIXEL band.
#'
#' @param date Character or Date. Acquisition date in `"YYYY-MM-DD"` format.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values: NDVI
#'   (-1 to 1). NA where QA_PIXEL indicates cloud, shadow, or snow.
#'
#' @section Data availability:
#' 2021-10-31 to present. 16-day revisit. 30 m spatial resolution.
#'
#' @references
#' U.S. Geological Survey. Landsat 9 Collection 2 Level-2 Science Products.
#' \doi{10.5066/P9OGBGM6}
#'
#' @family GEE readers
#' @seealso [read_gee()], [read_modis_ndvi()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' ndvi <- read_landsat(date = "2024-06-15",
#'                      region = terra::ext(138, 140, -36, -34))
#'
#' @export
read_landsat <- function(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- rlang::arg_match(tolower(backend))
  read_gee(
    "landsat_ndvi",
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
