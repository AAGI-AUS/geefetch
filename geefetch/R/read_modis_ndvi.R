#' Read MODIS Terra NDVI from Google Earth Engine
#'
#' @description
#' Reads MODIS/061/MOD13A2 (Terra Vegetation Indices 16-Day L3 1km)
#' from Google Earth Engine for the specified date. Returns a
#' [terra::rast()] SpatRaster with QA-masked, scaled NDVI values
#' (range: approximately -0.2 to 1.0).
#'
#' @param date Character or Date. Acquisition date in `"YYYY-MM-DD"` format.
#'   The nearest available 16-day composite containing this date is returned.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values: NDVI
#'   (scaled, approximately -0.2 to 1.0). NA where QA indicates poor quality.
#'
#' @section Data availability:
#' 2000-02-18 to present. 16-day composites. 1 km spatial resolution.
#'
#' @section QA masking:
#' Pixels with SummaryQA > 1 (snow/ice, cloudy) are masked to NA.
#' Only good (0) and marginal (1) quality pixels are retained.
#'
#' @references
#' Didan, K. (2021). MODIS/Terra Vegetation Indices 16-Day L3 Global 1km
#' SIN Grid V061. NASA EOSDIS Land Processes Distributed Active Archive
#' Center. \doi{10.5067/MODIS/MOD13A2.061}
#'
#' @family GEE readers
#' @seealso [read_gee()] for the general dispatcher, [collect_gee_data()]
#'   for batch point extraction.
#'
#' @examplesIf interactive()
#' ndvi <- read_modis_ndvi(date = "2024-06-15",
#'                         region = terra::ext(138, 140, -36, -34))
#' terra::plot(ndvi)
#'
#' @export
read_modis_ndvi <- function(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1
) {
  backend <- rlang::arg_match(backend)
  read_gee(
    "modis_ndvi",
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
