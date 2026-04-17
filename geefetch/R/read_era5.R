#' Read ERA5-Land climate data from Google Earth Engine
#'
#' @description
#' Reads ERA5-Land Daily Aggregated data (ECMWF/ERA5_LAND/DAILY_AGGR)
#' from Google Earth Engine. Supports temperature and precipitation
#' variables via the `variable` argument.
#'
#' @param date Character or Date. Date in `"YYYY-MM-DD"` format.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param variable Character. `"temperature"` (default) or `"precipitation"`.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values:
#'   - Temperature: degrees Celsius (converted from Kelvin)
#'   - Precipitation: mm (converted from metres)
#'
#' @section Data availability:
#' 1950-01-01 to present. Daily. ~11 km spatial resolution.
#'
#' @references
#' Munoz Sabater, J. (2019). ERA5-Land hourly data from 1950 to present.
#' Copernicus Climate Change Service (C3S) Climate Data Store (CDS).
#' \doi{10.24381/cds.e2161bac}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' temp <- read_era5(date = "2024-06-15",
#'                   region = terra::ext(138, 140, -36, -34))
#'
#' precip <- read_era5(date = "2024-06-15",
#'                     region = terra::ext(138, 140, -36, -34),
#'                     variable = "precipitation")
#'
#' @export
read_era5 <- function(
  date,
  region,
  variable = c("temperature", "precipitation"),
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- rlang::arg_match(tolower(backend))
  variable <- rlang::arg_match(tolower(variable))

  did <- data.table::fifelse(
    variable == "temperature",
    "era5_temp",
    "era5_precip"
  )

  read_gee(
    did,
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
