#' Read Sentinel-2 NDVI from Google Earth Engine
#'
#' @description
#' Computes NDVI from Copernicus Sentinel-2 MSI Level-2A harmonised
#' surface reflectance (COPERNICUS/S2_SR_HARMONIZED) on Google Earth
#' Engine. Cloud and shadow pixels are masked using the Scene
#' Classification Layer (SCL).
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
#'   (-1 to 1). NA where SCL indicates cloud, shadow, or snow.
#'
#' @section Data availability:
#' 2017-03-28 to present. ~5-day revisit. 10 m spatial resolution.
#'
#' @references
#' European Space Agency. Copernicus Sentinel-2 MSI Level-2A.
#'
#' @family GEE readers
#' @seealso [read_gee()], [read_modis_ndvi()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' ndvi <- read_sentinel2(date = "2024-06-15",
#'                        region = terra::ext(138, 139, -35, -34))
#'
#' @export
read_sentinel2 <- function(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- rlang::arg_match(tolower(backend))
  read_gee(
    "sentinel2_ndvi",
    date = date,
    region = region,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
