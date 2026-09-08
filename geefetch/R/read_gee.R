# read_gee.R — Central dispatcher for GEE dataset reads

#' Read data from Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Central dispatcher for all GEE dataset reads. Accepts a dataset identifier
#' (name or alias) and delegates to the appropriate internal handler.
#' For most use cases, prefer the convenience functions (e.g.,
#' [read_modis_ndvi()], [read_era5()]) which provide named parameters
#' and dataset-specific documentation.
#'
#' @param dataset_id Character. Dataset name or alias. Use [gee_datasets()]
#'   to list all available datasets.
#' @param ... Arguments passed to the dataset-specific handler. Common
#'   arguments include `date`, `region`, `collection`, `depth`. See the
#'   convenience function documentation for dataset-specific parameters.
#' @param backend Character. `"rest"` (default) or `"rgee"`. The REST backend
#'   requires no Python; the rgee backend supports advanced server-side
#'   computations.
#' @param cache Logical. Use disk cache for repeated queries? Default `TRUE`.
#' @param max_tries Integer. Maximum retry attempts for network failures.
#'   Default `3L`.
#' @param initial_delay Numeric. Initial delay in seconds before retry
#'   (doubles each attempt). Default `1`.
#'
#' @returns A [terra::rast()] SpatRaster object.
#'
#' @section Supported datasets:
#' Use [gee_datasets()] to list all available datasets with metadata.
#'
#' **Tier 1 — Specialised handlers (QA masking):**
#' - `modis_ndvi` — MODIS Terra NDVI 16-day 1km
#' - `modis_lst` — MODIS Terra LST 8-day 1km
#' - `era5_temp` — ERA5-Land daily 2m temperature
#' - `era5_precip` — ERA5-Land daily precipitation
#' - `chirps_precip` — CHIRPS daily precipitation
#' - `srtm_elevation` — NASA SRTM 30m elevation (static)
#'
#' **Tier 2 — Specialised handlers (soil, computed indices):**
#' - `slga_cly`, `slga_snd`, `slga_slt`, `slga_awc`, `slga_bdw`,
#'   `slga_phc`, `slga_nto` — SLGA soil properties (Australia, static)
#' - `sentinel2_ndvi` — Sentinel-2 NDVI 10m (computed, cloud-masked)
#' - `landsat_ndvi` — Landsat 9 NDVI 30m (computed, cloud-masked)
#'
#' **Tier 3 — Generic handler (global datasets):**
#' - `worldclim_bio` — WorldClim V1 bioclimatic variables ~1km (static)
#' - `openlandmap_soc` — OpenLandMap soil organic carbon 250m (static)
#' - `openlandmap_clay` — OpenLandMap clay content 250m (static)
#' - `openlandmap_ph` — OpenLandMap soil pH 250m (static)
#'
#' **User-registered:** Any dataset added via [gee_register_dataset()]
#' is automatically dispatchable through the generic handler.
#'
#' @section Region size and resampling:
#' Each request is capped at 2048x2048 pixels at the dataset's native
#' pixel scale, to bound REST payload size. A region that would exceed
#' this cap at the requested scale is resampled to fit, and [read_gee()]
#' warns with the native scale (in metres), the effective scale after
#' resampling, and the resulting pixel dimensions. The pixel scale is
#' fixed per dataset and is not a `read_gee()` argument, so request a
#' smaller region to keep the native resolution.
#'
#' @family GEE readers
#' @seealso [collect_gee_data()] for batch point extraction returning a
#'   [data.table::data.table].
#'
#' @examplesIf interactive()
#' # Using the dispatcher directly
#' ndvi <- read_gee("MODIS_NDVI", date = "2024-06-15",
#'                  region = terra::ext(138, 140, -36, -34))
#'
#' # Aliases are case-insensitive
#' elev <- read_gee("srtm", region = terra::ext(138, 140, -36, -34))
#'
#' # Equivalent convenience function, preferred
#' ndvi <- read_modis_ndvi(date = "2024-06-15",
#'                         region = terra::ext(138, 140, -36, -34))
#'
#' @export
read_gee <- function(
  dataset_id,
  ...,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
) {
  backend <- tolower(backend)
  backend <- rlang::arg_match(backend)

  # 1. Resolve alias to normalised dataset ID
  did <- .gee_resolve_id(dataset_id)

  # 2. Capture and validate args before any network call
  dots <- list(...)
  .gee_validate_args(did, dots)

  # 3. Check authentication
  .check_gee_auth(backend)

  # 4. Check cache
  if (cache) {
    cache_params <- c(list(backend = backend), dots)
    cached <- .cache_get(did, cache_params)
    if (!is.null(cached)) return(cached)
  }

  # 5. Dispatch to handler
  #    Tier 1: dataset-specific handlers with QA masking
  #    Tier 2: dataset-specific handlers (SLGA, computed indices)
  #    Default: generic handler (works for any metadata-only dataset)
  result <- switch(
    did,

    # Tier 1 — specialised handlers
    modis_ndvi = .read_gee_modis_ndvi(dots, backend, max_tries, initial_delay),
    modis_lst = .read_gee_modis_lst(dots, backend, max_tries, initial_delay),
    era5_temp = .read_gee_era5_temp(dots, backend, max_tries, initial_delay),
    era5_precip = .read_gee_era5_precip(
      dots,
      backend,
      max_tries,
      initial_delay
    ),
    chirps_precip = .read_gee_chirps(dots, backend, max_tries, initial_delay),
    srtm_elevation = .read_gee_srtm(dots, backend, max_tries, initial_delay),

    # Tier 2 — SLGA soil (attribute extracted from dataset ID)
    slga_cly = .read_gee_slga(dots, backend, max_tries, initial_delay, "CLY"),
    slga_snd = .read_gee_slga(dots, backend, max_tries, initial_delay, "SND"),
    slga_awc = .read_gee_slga(dots, backend, max_tries, initial_delay, "AWC"),
    slga_slt = .read_gee_slga(dots, backend, max_tries, initial_delay, "SLT"),
    slga_bdw = .read_gee_slga(dots, backend, max_tries, initial_delay, "BDW"),
    slga_phc = .read_gee_slga(dots, backend, max_tries, initial_delay, "PHC"),
    slga_nto = .read_gee_slga(dots, backend, max_tries, initial_delay, "NTO"),

    # Tier 2 — computed indices
    sentinel2_ndvi = .read_gee_sentinel2(
      dots,
      backend,
      max_tries,
      initial_delay
    ),
    landsat_ndvi = .read_gee_landsat(dots, backend, max_tries, initial_delay),

    # Default: generic handler (Tier 3 built-ins + user-registered)
    .read_gee_generic(dots, did, backend, max_tries, initial_delay)
  )

  # 6. Cache result
  if (cache) {
    .cache_set(did, cache_params, result)
  }

  result
}
