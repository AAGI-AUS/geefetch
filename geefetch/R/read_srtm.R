#' Read SRTM elevation data from Google Earth Engine
#'
#' @description
#' Reads USGS/SRTMGL1_003 (NASA Shuttle Radar Topography Mission
#' Digital Elevation Model) from Google Earth Engine. This is a static
#' dataset — no `date` argument is needed.
#'
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values:
#'   elevation in metres above sea level.
#'
#' @section Data availability:
#' Static (single acquisition, February 2000). 30 m spatial resolution.
#' Coverage: 60N to 56S.
#'
#' @references
#' Farr, T.G. et al. (2007). The Shuttle Radar Topography Mission.
#' Reviews of Geophysics, 45(2). \doi{10.1029/2005RG000183}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' elev <- read_srtm(region = terra::ext(138, 140, -36, -34))
#' terra::plot(elev)
#'
#' @export
read_srtm <- function(
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- rlang::arg_match(tolower(backend))
  read_gee(
    "srtm_elevation",
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
