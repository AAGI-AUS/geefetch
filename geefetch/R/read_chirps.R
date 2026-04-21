#' Read CHIRPS daily precipitation from Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Reads UCSB-CHG/CHIRPS/DAILY (Climate Hazards Group InfraRed
#' Precipitation With Station Data) from Google Earth Engine.
#' Returns a [terra::rast()] SpatRaster with precipitation in mm/day.
#'
#' @param date Character or Date. Date in `"YYYY-MM-DD"` format.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values:
#'   precipitation in mm/day.
#'
#' @section Data availability:
#' 1981-01-01 to near-present. Daily. ~5.5 km spatial resolution.
#' Coverage: 50S-50N (land only).
#'
#' @references
#' Funk, C. et al. (2015). The climate hazards infrared precipitation with
#' stations -- a new environmental record for monitoring extremes.
#' Scientific Data, 2, 150066. \doi{10.1038/sdata.2015.66}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' precip <- read_chirps(date = "2024-06-15",
#'                       region = terra::ext(138, 140, -36, -34))
#'
#' @export
read_chirps <- function(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- tolower(backend)
  backend <- rlang::arg_match(backend)
  read_gee(
    "chirps_precip",
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
