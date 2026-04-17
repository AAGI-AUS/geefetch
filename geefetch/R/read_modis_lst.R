#' Read MODIS Terra Land Surface Temperature from Google Earth Engine
#'
#' @description
#' Reads MODIS/061/MOD11A2 (Terra Land Surface Temperature/Emissivity
#' 8-Day L3 1km) from Google Earth Engine. Returns a [terra::rast()]
#' SpatRaster with QA-masked daytime LST values in Kelvin.
#'
#' @param date Character or Date. Acquisition date in `"YYYY-MM-DD"` format.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values: LST in
#'   Kelvin. NA where QA indicates cloud or poor quality.
#'
#' @section Data availability:
#' 2000-02-24 to present. 8-day composites. 1 km spatial resolution.
#'
#' @section QA masking:
#' Pixels where QC_Day bits 0-1 are not 00 (good quality) are masked to NA.
#'
#' @references
#' Wan, Z., Hook, S. & Hulley, G. (2021). MODIS/Terra Land Surface
#' Temperature/Emissivity 8-Day L3 Global 1km SIN Grid V061. NASA
#' EOSDIS LP DAAC. \doi{10.5067/MODIS/MOD11A2.061}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' lst <- read_modis_lst(date = "2024-06-15",
#'                       region = terra::ext(138, 140, -36, -34))
#'
#' @export
read_modis_lst <- function(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1
) {
  backend <- match.arg(backend)
  read_gee(
    "modis_lst",
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
