#' Read WorldClim bioclimatic variables from Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Reads WorldClim V2 bioclimatic variables (WORLDCLIM/V2/BIO) from
#' Google Earth Engine. This is a static dataset representing 1970-2000
#' climate normals at ~1 km resolution.
#'
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param variable Character. Bioclimatic variable band name. One of
#'   `"bio01"` through `"bio19"`. Default `"bio01"` (annual mean
#'   temperature, degrees C x 10).
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values depend
#'   on the variable (see WorldClim documentation).
#'
#' @section Data availability:
#' Static (1970-2000 normals). Global land. ~1 km spatial resolution.
#'
#' @section Variables:
#' - bio01: Annual Mean Temperature (deg C x 10)
#' - bio02: Mean Diurnal Range
#' - bio03: Isothermality
#' - bio04: Temperature Seasonality
#' - bio05-bio11: Various temperature metrics
#' - bio12: Annual Precipitation (mm)
#' - bio13-bio19: Various precipitation metrics
#'
#' @references
#' Fick, S.E. & Hijmans, R.J. (2017). WorldClim 2: new 1km spatial
#' resolution climate surfaces for global land areas. International
#' Journal of Climatology, 37(12), 4302-4315. \doi{10.1002/joc.5086}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' # Annual mean temperature
#' temp <- read_worldclim(region = terra::ext(138, 140, -36, -34))
#'
#' # Annual precipitation
#' precip <- read_worldclim(region = terra::ext(138, 140, -36, -34),
#'                          variable = "bio12")
#'
#' @export
read_worldclim <- function(
  region,
  variable = "bio01",
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- rlang::arg_match(tolower(backend))

  # Override the band in metadata via dots
  read_gee(
    "worldclim_bio",
    region = region,
    variable = variable,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
