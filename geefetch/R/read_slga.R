#' Read SLGA soil data from Google Earth Engine
#'
#' @description
#' Reads CSIRO Soil and Landscape Grid of Australia (SLGA) data from
#' Google Earth Engine. Supports 7 soil attributes, 6 depth layers,
#' and 3 statistics. This is a static dataset (no date required).
#'
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param collection Character. Soil attribute to extract. One of:
#'   - `"CLY"` — Clay content (percent)
#'   - `"SND"` — Sand content (percent)
#'   - `"SLT"` — Silt content (percent)
#'   - `"AWC"` — Available water capacity (mm)
#'   - `"BDW"` — Bulk density (g/cm3)
#'   - `"PHC"` — pH (CaCl2)
#'   - `"NTO"` — Total nitrogen (percent)
#'
#'   Default `"CLY"`.
#' @param depth Character. Depth layer. One of `"0-5"`, `"5-15"`,
#'   `"15-30"`, `"30-60"`, `"60-100"`, `"100-200"`. Default `"0-5"`.
#' @param stat Character. Statistic. `"mean"` (default), `"ci_lower"`
#'   (5th percentile), or `"ci_upper"` (95th percentile).
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Use disk cache? Default `TRUE`.
#' @param max_tries Integer. Retry attempts. Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds. Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster. CRS: EPSG:4326. Values depend
#'   on the collection (e.g., percent for clay, pH units for PHC).
#'
#' @section Data availability:
#' Static dataset. Australia only. 90 m spatial resolution.
#' 6 depth layers: 0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm.
#'
#' @references
#' Viscarra Rossel, R.A. et al. (2015). A digital soil map of Australia.
#' Soil Research, 53(7), 745-757. \doi{10.1071/SR15158}
#'
#' @family GEE readers
#' @seealso [read_gee()], [collect_gee_data()]
#'
#' @examplesIf interactive()
#' # Clay content, 0-5cm, mean
#' clay <- read_slga(region = terra::ext(138, 140, -36, -34))
#'
#' # pH at 30-60cm depth
#' ph <- read_slga(region = terra::ext(138, 140, -36, -34),
#'                 collection = "PHC", depth = "30-60")
#'
#' # Sand content with confidence interval
#' sand_lo <- read_slga(region = terra::ext(138, 140, -36, -34),
#'                      collection = "SND", stat = "ci_lower")
#'
#' @export
read_slga <- function(
  region,
  collection = c("CLY", "SND", "SLT", "AWC", "BDW", "PHC", "NTO"),
  depth = "0-5",
  stat = c("mean", "ci_lower", "ci_upper"),
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1
) {
  backend <- rlang::arg_match(backend)
  collection <- rlang::arg_match(collection)
  stat <- rlang::arg_match(stat)

  did <- paste0("slga_", tolower(collection))

  read_gee(
    did,
    region = region,
    depth = depth,
    stat = stat,
    backend = backend,
    cache = cache,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}
