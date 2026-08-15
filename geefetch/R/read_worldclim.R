#' Read WorldClim bioclimatic variables from Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Reads WorldClim V1 bioclimatic variables (WORLDCLIM/V1/BIO) from
#' Google Earth Engine. This is a static dataset representing 1960-1990
#' climate normals at ~1 km resolution. Note that Google Earth Engine hosts
#' WorldClim version 1, not version 2; the two differ in both their
#' normal period and their source publication.
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
#' Static (1960-1990 normals). Global land. ~1 km spatial resolution.
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
#' Hijmans, R.J., Cameron, S.E., Parra, J.L., Jones, P.G. & Jarvis, A.
#' (2005). Very High Resolution Interpolated Climate Surfaces for Global
#' Land Areas. International Journal of Climatology, 25(15), 1965-1978.
#' \doi{10.1002/joc.1276}
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
  backend <- tolower(backend)
  backend <- rlang::arg_match(backend)

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
