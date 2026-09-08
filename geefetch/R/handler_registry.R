# handler_registry.R — Dataset alias table, metadata, and catalogue
#
# This file defines the static mapping from user-facing dataset names/aliases
# to normalised internal IDs, plus per-dataset metadata used by handlers.
# Follows the same pattern as nert's .TERN_ALIASES and .SLGA_META.

# ---- Alias table ----
# Maps user-facing names (case-insensitive lookup) to normalised IDs.
# The dispatcher (read_gee) resolves aliases via .gee_resolve_id().

.GEE_ALIASES <- c(
  # Tier 1 — Launch datasets
  MODIS_NDVI = "modis_ndvi",
  NDVI = "modis_ndvi",
  MODIS_LST = "modis_lst",
  LST = "modis_lst",
  ERA5_TEMP = "era5_temp",
  ERA5_PRECIP = "era5_precip",
  CHIRPS = "chirps_precip",
  CHIRPS_PRECIP = "chirps_precip",
  SRTM = "srtm_elevation",
  SRTM_ELEVATION = "srtm_elevation",
  ELEVATION = "srtm_elevation",

  # Tier 2 — Extended datasets

  SLGA_CLY = "slga_cly",
  SLGA_SND = "slga_snd",
  SLGA_AWC = "slga_awc",
  SLGA_SLT = "slga_slt",
  SLGA_BDW = "slga_bdw",
  SLGA_PHC = "slga_phc",
  SLGA_NTO = "slga_nto",
  SENTINEL2 = "sentinel2_ndvi",
  SENTINEL2_NDVI = "sentinel2_ndvi",
  LANDSAT = "landsat_ndvi",
  LANDSAT_NDVI = "landsat_ndvi",

  # Tier 3 — GEE-hosted global datasets
  WORLDCLIM = "worldclim_bio",
  WORLDCLIM_BIO = "worldclim_bio",
  BIOCLIM = "worldclim_bio",
  OPENLANDMAP_SOC = "openlandmap_soc",
  OPENLANDMAP_CLAY = "openlandmap_clay",
  OPENLANDMAP_PH = "openlandmap_ph"
)


# ---- Dataset metadata ----
# Each entry is a list containing everything a handler needs to construct
# the correct GEE extraction request. Handlers read from this table rather
# than hard-coding collection IDs, bands, or scale factors.

.GEE_META <- list(
  # -- Tier 1: Launch datasets --

  modis_ndvi = list(
    collection = "MODIS/061/MOD13A2",
    bands = "NDVI",
    scale = 1000L,
    temporal = "16day",
    qa_band = "SummaryQA",
    scale_factor = 0.0001,
    offset = 0,
    valid_range = c(-2000L, 10000L),
    unit = "NDVI index",
    domain = "Vegetation",
    description = "MODIS Terra Vegetation Indices 16-Day L3 1km",
    date_start = "2000-02-18",
    date_end = NA_character_,
    citation = paste0(
      "Didan, K. (2021). MODIS/Terra Vegetation Indices 16-Day L3 Global ",
      "1km SIN Grid V061. NASA EOSDIS LP DAAC. doi:10.5067/MODIS/MOD13A2.061"
    )
  ),

  modis_lst = list(
    collection = "MODIS/061/MOD11A2",
    bands = "LST_Day_1km",
    scale = 1000L,
    temporal = "8day",
    qa_band = "QC_Day",
    scale_factor = 0.02,
    offset = 0,
    valid_range = c(7500L, 65535L),
    unit = "Kelvin",
    domain = "Temperature",
    description = "MODIS Terra Land Surface Temperature 8-Day L3 1km",
    date_start = "2000-02-24",
    date_end = NA_character_,
    citation = paste0(
      "Wan, Z., Hook, S. & Hulley, G. (2021). MODIS/Terra Land Surface ",
      "Temperature/Emissivity 8-Day L3 Global 1km SIN Grid V061. ",
      "NASA EOSDIS LP DAAC. doi:10.5067/MODIS/MOD11A2.061"
    )
  ),

  era5_temp = list(
    collection = "ECMWF/ERA5_LAND/DAILY_AGGR",
    bands = "temperature_2m",
    scale = 11132L,
    temporal = "daily",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = -273.15,
    valid_range = c(NA_real_, NA_real_),
    unit = "degrees Celsius (after offset)",
    domain = "Climate",
    description = "ERA5-Land Daily Aggregated 2m Air Temperature",
    date_start = "1950-01-01",
    date_end = NA_character_,
    citation = paste0(
      "Munoz Sabater, J. (2019). ERA5-Land hourly data from 1950 to present. ",
      "Copernicus Climate Change Service (C3S) Climate Data Store (CDS). ",
      "doi:10.24381/cds.e2161bac"
    )
  ),

  era5_precip = list(
    collection = "ECMWF/ERA5_LAND/DAILY_AGGR",
    bands = "total_precipitation_sum",
    scale = 11132L,
    temporal = "daily",
    qa_band = NA_character_,
    scale_factor = 1000,
    offset = 0,
    valid_range = c(NA_real_, NA_real_),
    unit = "mm (after scaling from metres)",
    domain = "Climate",
    description = "ERA5-Land Daily Aggregated Total Precipitation",
    date_start = "1950-01-01",
    date_end = NA_character_,
    citation = paste0(
      "Munoz Sabater, J. (2019). ERA5-Land hourly data from 1950 to present. ",
      "Copernicus Climate Change Service (C3S) Climate Data Store (CDS). ",
      "doi:10.24381/cds.e2161bac"
    )
  ),

  chirps_precip = list(
    collection = "UCSB-CHG/CHIRPS/DAILY",
    bands = "precipitation",
    scale = 5566L,
    temporal = "daily",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, NA_real_),
    unit = "mm/day",
    domain = "Precipitation",
    description = "CHIRPS Daily: Climate Hazards Group InfraRed Precipitation With Station Data",
    date_start = "1981-01-01",
    date_end = NA_character_,
    citation = paste0(
      "Funk, C. et al. (2015). The climate hazards infrared precipitation with ",
      "stations -- a new environmental record for monitoring extremes. ",
      "Scientific Data, 2, 150066. doi:10.1038/sdata.2015.66"
    )
  ),

  srtm_elevation = list(
    collection = "USGS/SRTMGL1_003",
    bands = "elevation",
    scale = 30L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(-32768L, 32767L),
    unit = "metres",
    domain = "Topography",
    description = "NASA SRTM Digital Elevation 30m",
    date_start = "2000-02-11",
    date_end = "2000-02-22",
    citation = paste0(
      "Farr, T.G. et al. (2007). The Shuttle Radar Topography Mission. ",
      "Reviews of Geophysics, 45(2). doi:10.1029/2005RG000183"
    )
  ),

  # -- Tier 2: Extended datasets (handlers to be implemented in Phase 4) --

  slga_cly = list(
    collection = "CSIRO/SLGA/CLY",
    bands = "CLY_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, 100),
    unit = "percent",
    domain = "Soil (AU)",
    description = "SLGA Clay Content 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    # Citation matches the authority's own `sci:citation` for CSIRO/SLGA
    # (GEE STAC) and the Crossref record for the DOI (both diffed 2026-08-15).
    citation = paste0(
      "Viscarra Rossel, R.A., Chen, C., Grundy, M.J., Searle, R., ",
      "Clifford, D. & Campbell, P.H. (2015). The Australian ",
      "three-dimensional soil grid: Australia's contribution to the ",
      "GlobalSoilMap project. Soil Research, 53(8), 845-864. ",
      "doi:10.1071/SR14366"
    )
  ),

  slga_snd = list(
    collection = "CSIRO/SLGA/SND",
    bands = "SND_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, 100),
    unit = "percent",
    domain = "Soil (AU)",
    description = "SLGA Sand Content 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  slga_awc = list(
    collection = "CSIRO/SLGA/AWC",
    bands = "AWC_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, NA_real_),
    unit = "mm",
    domain = "Soil (AU)",
    description = "SLGA Available Water Capacity 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  slga_slt = list(
    collection = "CSIRO/SLGA/SLT",
    bands = "SLT_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, 100),
    unit = "percent",
    domain = "Soil (AU)",
    description = "SLGA Silt Content 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  slga_bdw = list(
    collection = "CSIRO/SLGA/BDW",
    bands = "BDW_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, NA_real_),
    unit = "g/cm3",
    domain = "Soil (AU)",
    description = "SLGA Bulk Density 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  slga_phc = list(
    collection = "CSIRO/SLGA/pHc",
    bands = "pHc_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, 14),
    unit = "pH (CaCl2)",
    domain = "Soil (AU)",
    description = "SLGA pH (CaCl2) 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  slga_nto = list(
    collection = "CSIRO/SLGA/NTO",
    bands = "NTO_000_005_EV",
    scale = 90L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0, NA_real_),
    unit = "percent",
    domain = "Soil (AU)",
    description = "SLGA Total Nitrogen 0-5cm (Australia)",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Viscarra Rossel, R.A. et al. (2015). doi:10.1071/SR14366"
  ),

  sentinel2_ndvi = list(
    collection = "COPERNICUS/S2_SR_HARMONIZED",
    bands = c("B8", "B4"),
    composite = "mosaic",
    index = "ndvi",
    scale = 10L,
    temporal = "5day",
    qa_band = "SCL",
    scale_factor = 0.0001,
    offset = 0,
    valid_range = c(0L, 10000L),
    unit = "NDVI index (computed from B8, B4)",
    domain = "Vegetation",
    description = "Sentinel-2 MSI NDVI (computed) 10m",
    date_start = "2017-03-28",
    date_end = NA_character_,
    citation = paste0(
      "European Space Agency. Copernicus Sentinel-2 MSI Level-2A. ",
      "https://developers.google.com/earth-engine/datasets/catalog/",
      "COPERNICUS_S2_SR_HARMONIZED"
    )
  ),

  landsat_ndvi = list(
    collection = "LANDSAT/LC09/C02/T1_L2",
    bands = c("SR_B5", "SR_B4"),
    composite = "mosaic",
    index = "ndvi",
    scale = 30L,
    temporal = "16day",
    qa_band = "QA_PIXEL",
    scale_factor = 0.0000275,
    offset = -0.2,
    valid_range = c(0L, 65535L),
    unit = "NDVI index (computed from SR_B5, SR_B4)",
    domain = "Vegetation",
    description = "Landsat 9 OLI-2 NDVI (computed) 30m",
    date_start = "2021-10-31",
    date_end = NA_character_,
    citation = paste0(
      "U.S. Geological Survey. Landsat 9 Collection 2 Level-2 Science Products. ",
      "doi:10.5066/P9OGBGM6"
    )
  ),

  # -- Tier 3: GEE-hosted global datasets --

  worldclim_bio = list(
    collection = "WORLDCLIM/V1/BIO",
    bands = "bio01",
    scale = 927L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 0.1,
    offset = 0,
    valid_range = c(NA_real_, NA_real_),
    unit = "varies by variable (bio01 = annual mean temp, deg C x 10)",
    domain = "Bioclimatic",
    description = "WorldClim V1 Bioclimatic Variables ~1km",
    date_start = NA_character_,
    date_end = NA_character_,
    # Citation is the authority's own `sci:citation` for WORLDCLIM/V1/BIO
    # (GEE STAC, diffed 2026-08-15). The asset GEE hosts is WorldClim
    # version 1, so Fick & Hijmans (2017) -- the WorldClim 2 paper -- is the
    # wrong reference for these values.
    citation = paste0(
      "Hijmans, R.J., S.E. Cameron, J.L. Parra, P.G. Jones and A. Jarvis ",
      "(2005). Very High Resolution Interpolated Climate Surfaces for ",
      "Global Land Areas. International Journal of Climatology, 25(15), ",
      "1965-1978. doi:10.1002/joc.1276"
    )
  ),

  openlandmap_soc = list(
    collection = "OpenLandMap/SOL/SOL_ORGANIC-CARBON_USDA-6A1C_M/v02",
    bands = "b0",
    scale = 250L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 5,
    offset = 0,
    valid_range = c(0L, 120L),
    unit = "g/kg (after scaling)",
    domain = "Soil (Global)",
    description = "OpenLandMap Soil Organic Carbon 0cm 250m",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = paste0(
      "Hengl, T. et al. (2017). SoilGrids250m: Global gridded soil ",
      "information based on machine learning. PLoS ONE, 12(2), e0169748. ",
      "doi:10.1371/journal.pone.0169748"
    )
  ),

  openlandmap_clay = list(
    collection = "OpenLandMap/SOL/SOL_CLAY-WFRACTION_USDA-3A1A1A_M/v02",
    bands = "b0",
    scale = 250L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 1,
    offset = 0,
    valid_range = c(0L, 100L),
    unit = "percent",
    domain = "Soil (Global)",
    description = "OpenLandMap Clay Content 0cm 250m",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Hengl, T. et al. (2017). doi:10.1371/journal.pone.0169748"
  ),

  openlandmap_ph = list(
    collection = "OpenLandMap/SOL/SOL_PH-H2O_USDA-4C1A2A_M/v02",
    bands = "b0",
    scale = 250L,
    temporal = "static",
    qa_band = NA_character_,
    scale_factor = 0.1,
    offset = 0,
    valid_range = c(20L, 110L),
    unit = "pH (after scaling)",
    domain = "Soil (Global)",
    description = "OpenLandMap Soil pH (H2O) 0cm 250m",
    date_start = NA_character_,
    date_end = NA_character_,
    citation = "Hengl, T. et al. (2017). doi:10.1371/journal.pone.0169748"
  )
)


# ---- SLGA depth and stat metadata ----
# Used by read_slga() and the SLGA handler to construct correct band names.

.SLGA_DEPTHS <- c(
  "000_005",
  "005_015",
  "015_030",
  "030_060",
  "060_100",
  "100_200"
)

.SLGA_DEPTH_LABELS <- c(
  "000_005" = "0-5 cm",
  "005_015" = "5-15 cm",
  "015_030" = "15-30 cm",
  "030_060" = "30-60 cm",
  "060_100" = "60-100 cm",
  "100_200" = "100-200 cm"
)

.SLGA_STATS <- c("EV", "05", "95")

.SLGA_STAT_LABELS <- c(
  EV = "mean",
  "05" = "ci_lower",
  "95" = "ci_upper"
)

.SLGA_ATTRIBUTES <- c("CLY", "SND", "AWC", "SLT", "BDW", "PHC", "NTO")

# Map the user-facing attribute code to the GEE band-name prefix. GEE band names
# are case-sensitive: the CSIRO/SLGA pH band is `pHc_*`, not `PHC_*` (grounded
# 2026-06-09 against the GEE STAC band list for CSIRO/SLGA). The others match
# their codes verbatim. Keep the user-facing code uppercase ("PHC") and resolve
# the real prefix here so a `select()` hits the band the authority actually
# advertises.
.SLGA_BAND_PREFIX <- c(
  CLY = "CLY", SND = "SND", AWC = "AWC", SLT = "SLT",
  BDW = "BDW", PHC = "pHc", NTO = "NTO"
)


# ---- Alias resolution ----

#' Resolve a user-supplied dataset identifier to a normalised internal ID
#'
#' @param dataset_id Character. User-supplied name or alias.
#'
#' @returns Character. Normalised dataset ID (e.g., `"modis_ndvi"`).
#'
#' @noRd
.gee_resolve_id <- function(dataset_id) {
  if (!is.character(dataset_id) || length(dataset_id) != 1L) {
    cli::cli_abort(c(
      "{.arg dataset_id} must be a single character string.",
      i = "Use {.code gee_datasets()} to list available datasets."
    ))
  }

  # Try direct match against normalised IDs (built-in + user-registered)
  normalised <- tolower(trimws(dataset_id))
  combined_names <- names(.gee_combined_meta())
  if (normalised %in% combined_names) {
    return(normalised)
  }

  # Try alias lookup (case-insensitive)
  upper <- toupper(normalised)
  if (upper %in% names(.GEE_ALIASES)) {
    return(unname(.GEE_ALIASES[upper]))
  }

  # Also try the normalised form as-is against alias values
  if (normalised %in% .GEE_ALIASES) {
    return(normalised)
  }

  .gee_not_implemented(dataset_id)
}


#' Emit an informative error for unsupported datasets
#'
#' @param dataset_id Character. The unrecognised identifier.
#'
#' @noRd
.gee_not_implemented <- function(dataset_id) {
  available <- sort(unique(c(names(.GEE_ALIASES), names(.GEE_META))))
  cli::cli_abort(c(
    "Dataset {.val {dataset_id}} is not recognised.",
    i = "Available datasets: {.val {names(.GEE_META)}}",
    i = "Available aliases: {.val {names(.GEE_ALIASES)}}",
    i = "Use {.code gee_datasets()} to browse all datasets with metadata."
  ))
}


# ---- User-facing catalogue ----

#' List available GEE datasets
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Returns a [data.table::data.table] of all datasets available in the
#' geefetch registry, including their GEE collection ID, domain,
#' spatial resolution, temporal resolution, and description.
#'
#' Custom datasets registered via [gee_register_dataset()] are included.
#'
#' @param domain Character. Filter to a specific domain (e.g., `"Vegetation"`,
#'   `"Climate"`, `"Soil (AU)"`). Default `NULL` returns all.
#'
#' @returns A [data.table::data.table] with columns:
#' \describe{
#'   \item{dataset}{Normalised dataset ID (use with [read_gee()])}
#'   \item{collection}{GEE ImageCollection ID}
#'   \item{domain}{Scientific domain}
#'   \item{resolution}{Spatial resolution description}
#'   \item{temporal}{Temporal resolution}
#'   \item{description}{Human-readable description}
#'   \item{date_start}{Earliest available date (or NA for static)}
#' }
#'
#' @family utilities
#' @seealso [read_gee()], [gee_register_dataset()]
#'
#' @examplesIf interactive()
#' gee_datasets()
#' gee_datasets(domain = "Vegetation")
#'
#' @export
gee_datasets <- function(domain = NULL) {
  # Build from .GEE_META + any user-registered datasets
  meta_source <- .gee_combined_meta()

  dt <- rbindlist(lapply(names(meta_source), function(nm) {
    m <- meta_source[[nm]]
    data.table(
      dataset = nm,
      collection = m$collection,
      domain = m$domain %||% NA_character_,
      resolution = paste0(m$scale, "m"),
      temporal = m$temporal %||% NA_character_,
      description = m$description %||% NA_character_,
      date_start = m$date_start %||% NA_character_
    )
  }))

  if (!is.null(domain)) {
    domain_filter <- domain
    dt <- dt[domain == domain_filter]
  }

  dt[]
}


#' Get combined metadata (built-in + user-registered)
#'
#' @returns Named list of all dataset metadata entries.
#'
#' @noRd
.gee_combined_meta <- function() {
  user_meta <- .geefetch_env$user_meta
  if (is.null(user_meta) || length(user_meta) == 0L) {
    return(.GEE_META)
  }
  c(.GEE_META, user_meta)
}


#' Register a custom GEE dataset
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Adds a user-defined GEE collection to the geefetch registry for the
#' current R session. Once registered, the dataset can be used with
#' [read_gee()] and [collect_gee_data()] like any built-in dataset.
#'
#' @param name Character. Short, unique identifier for the dataset
#'   (e.g., `"soilgrids_ocs"`). Will be normalised to lowercase.
#' @param collection Character. GEE ImageCollection ID
#'   (e.g., `"projects/soilgrids-isric/ocs"`).
#' @param bands Character vector. Band name(s) to extract.
#' @param scale Integer. Native resolution in metres.
#' @param temporal Character. Temporal resolution: `"daily"`, `"8day"`,
#'   `"16day"`, `"monthly"`, `"5day"`, or `"static"`.
#' @param description Character. Human-readable dataset description.
#' @param domain Character. Scientific domain (e.g., `"Soil"`,
#'   `"Vegetation"`). Default `"User-defined"`.
#' @param qa_band Character. QA band name, or `NA` if none.
#'   Default `NA_character_`.
#' @param scale_factor Numeric. Multiply raw values by this factor.
#'   Default `1`.
#' @param offset Numeric. Add this to values after scaling. Default `0`.
#' @param citation Character. Citation string. Default `NA_character_`.
#'
#' @returns `NULL`, invisibly. Called for side effects (registration).
#'
#' @family utilities
#' @seealso [gee_datasets()], [read_gee()]
#'
#' @examplesIf interactive()
#' gee_register_dataset(
#'   name        = "soilgrids_ocs",
#'   collection  = "projects/soilgrids-isric/ocs",
#'   bands       = "ocs_0-30cm_mean",
#'   scale       = 250L,
#'   temporal    = "static",
#'   description = "SoilGrids Organic Carbon Stock 0-30cm"
#' )
#'
#' # Now available in the registry
#' gee_datasets()
#' read_gee("soilgrids_ocs")
#'
#' @export
gee_register_dataset <- function(
  name,
  collection,
  bands,
  scale,
  temporal,
  description,
  domain = "User-defined",
  qa_band = NA_character_,
  scale_factor = 1,
  offset = 0,
  citation = NA_character_
) {
  check_required(name)
  check_required(collection)
  check_required(bands)
  check_required(scale)
  check_required(temporal)
  check_required(description)

  name <- tolower(trimws(name))

  if (name %in% names(.GEE_META)) {
    cli::cli_abort(c(
      "Cannot overwrite built-in dataset {.val {name}}.",
      i = "Choose a different name for your custom dataset."
    ))
  }

  temporal <- arg_match(
    temporal,
    c("daily", "8day", "16day", "monthly", "5day", "static")
  )

  entry <- list(
    collection = collection,
    bands = bands,
    scale = as.integer(scale),
    temporal = temporal,
    qa_band = qa_band,
    scale_factor = scale_factor,
    offset = offset,
    valid_range = c(NA_real_, NA_real_),
    unit = NA_character_,
    domain = domain,
    description = description,
    date_start = NA_character_,
    date_end = NA_character_,
    citation = citation
  )

  if (is.null(.geefetch_env$user_meta)) {
    .geefetch_env$user_meta <- list()
  }
  .geefetch_env$user_meta[[name]] <- entry

  cli::cli_inform(c(
    v = "Registered custom dataset {.val {name}}.",
    i = "Collection: {.val {collection}}",
    i = "Available via {.code read_gee({.val {name}})} and {.code collect_gee_data()}."
  ))

  invisible(NULL)
}
