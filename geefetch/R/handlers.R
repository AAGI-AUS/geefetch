# handlers.R — Internal dataset-specific handler functions
#
# Each handler builds a GEE expression tailored to its dataset:
# collection-specific QA masking, band selection, computed indices, etc.
#
# Handler contract:
#   Input:  dots (named list from user), backend, max_tries, initial_delay
#   Output: terra::rast() SpatRaster
#
# Handlers are called by the read_gee() dispatcher via switch().

# ---- MODIS NDVI (MOD13A2) ----

#' @noRd
.read_gee_modis_ndvi <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$modis_ndvi
  date <- .validate_date(dots$date, "date", "modis_ndvi")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    # Build expression with QA masking
    date_end <- date + 16L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    # Apply QA mask before band selection
    img_masked <- .ee_mask_modis_vi(img)
    img_ndvi <- .ee_select(img_masked, "NDVI")
    img_scaled <- .ee_scale_offset(img_ndvi, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      "NDVI",
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- MODIS LST (MOD11A2) ----

#' @noRd
.read_gee_modis_lst <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$modis_lst
  date <- .validate_date(dots$date, "date", "modis_lst")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 8L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    img_masked <- .ee_mask_modis_lst(img)
    img_lst <- .ee_select(img_masked, "LST_Day_1km")
    img_scaled <- .ee_scale_offset(img_lst, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      "LST_Day_1km",
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- ERA5-Land Temperature ----

#' @noRd
.read_gee_era5_temp <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$era5_temp
  date <- .validate_date(dots$date, "date", "era5_temp")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 1L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    img_band <- .ee_select(img, meta$bands)
    img_scaled <- .ee_scale_offset(img_band, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      meta$bands,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- ERA5-Land Precipitation ----

#' @noRd
.read_gee_era5_precip <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$era5_precip
  date <- .validate_date(dots$date, "date", "era5_precip")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 1L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    img_band <- .ee_select(img, meta$bands)
    img_scaled <- .ee_scale_offset(img_band, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      meta$bands,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- CHIRPS Daily Precipitation ----

#' @noRd
.read_gee_chirps <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$chirps_precip
  date <- .validate_date(dots$date, "date", "chirps_precip")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 1L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    img_band <- .ee_select(img, meta$bands)
    # No QA masking needed; scale_factor = 1, offset = 0

    .rest_extract_raster_expr(
      img_band,
      region,
      meta,
      meta$bands,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- SRTM Elevation (static) ----

#' @noRd
.read_gee_srtm <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$srtm_elevation
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    img <- .ee_load_image(meta$collection)
    img_band <- .ee_select(img, meta$bands)

    .rest_extract_raster_expr(
      img_band,
      region,
      meta,
      meta$bands,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, NULL, region, max_tries, initial_delay)
  }
}


# ---- Helper: extract raster from a built expression ----

#' Internal helper for REST raster extraction
#' @noRd
.rest_extract_raster_expr <- function(
  expr,
  region,
  meta,
  bands,
  max_tries,
  initial_delay
) {
  if (is.null(region)) {
    cli::cli_abort(c(
      "{.arg region} is required for raster extraction.",
      "i" = "Provide an {.cls sf}, {.cls sfc}, or {.cls SpatExtent} object.",
      "i" = "Example: {.code terra::ext(138, 140, -36, -34)}"
    ))
  }

  bbox <- sf::st_bbox(region)
  grid <- .build_grid(bbox = bbox, scale = meta$scale)

  .rest_compute_pixels(
    expression = expr,
    grid = grid,
    bands = if (is.character(bands)) as.list(bands) else NULL,
    max_tries = max_tries,
    initial_delay = initial_delay
  )
}


# ===========================================================================
# Tier 2: Extended dataset handlers
# ===========================================================================

# ---- SLGA Soil (Australia, static) ----

#' @noRd
.read_gee_slga <- function(
  dots,
  backend,
  max_tries,
  initial_delay,
  attribute = "CLY"
) {
  # Resolve depth and stat from user args or defaults
  depth_code <- .slga_depth_to_code(dots$depth %||% "0-5")
  stat_code <- .slga_stat_to_code(dots$stat %||% "mean")

  # Construct band name: e.g., CLY_000_005_EV
  band_name <- paste0(attribute, "_", depth_code, "_", stat_code)

  # Use the base SLGA meta but override bands
  meta_key <- paste0("slga_", tolower(attribute))
  meta <- .GEE_META[[meta_key]]
  if (is.null(meta)) {
    meta <- .GEE_META$slga_cly
  } # fallback

  region <- .validate_region(dots$region)

  if (backend == "rest") {
    img <- .ee_load_image(meta$collection)
    img_band <- .ee_select(img, band_name)
    img_scaled <- .ee_scale_offset(img_band, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      band_name,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, NULL, region, max_tries, initial_delay)
  }
}

#' Convert user-friendly depth to SLGA band code
#' @noRd
.slga_depth_to_code <- function(depth) {
  map <- c(
    "0-5" = "000_005",
    "5-15" = "005_015",
    "15-30" = "015_030",
    "30-60" = "030_060",
    "60-100" = "060_100",
    "100-200" = "100_200"
  )
  code <- map[depth]
  if (is.na(code)) {
    cli::cli_abort(c(
      "Invalid SLGA depth: {.val {depth}}.",
      "i" = "Valid depths: {.val {names(map)}}"
    ))
  }
  unname(code)
}

#' Convert user-friendly stat to SLGA band suffix
#' @noRd
.slga_stat_to_code <- function(stat) {
  map <- c(mean = "EV", ci_lower = "05", ci_upper = "95")
  code <- map[stat]
  if (is.na(code)) {
    cli::cli_abort(c(
      "Invalid SLGA stat: {.val {stat}}.",
      "i" = "Valid stats: {.val {names(map)}}"
    ))
  }
  unname(code)
}


# ---- Sentinel-2 NDVI (computed index) ----

#' @noRd
.read_gee_sentinel2 <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$sentinel2_ndvi
  date <- .validate_date(dots$date, "date", "sentinel2_ndvi")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 5L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    # Apply SCL cloud masking
    img_masked <- .ee_mask_s2_scl(img)

    # Compute NDVI from B8 (NIR) and B4 (Red)
    ndvi <- .ee_normalized_difference(img_masked, "B8", "B4")

    .rest_extract_raster_expr(
      ndvi,
      region,
      meta,
      NULL,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- Landsat 9 NDVI (computed index) ----

#' @noRd
.read_gee_landsat <- function(dots, backend, max_tries, initial_delay) {
  meta <- .GEE_META$landsat_ndvi
  date <- .validate_date(dots$date, "date", "landsat_ndvi")
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    date_end <- date + 16L
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)

    # Apply QA_PIXEL cloud masking
    img_masked <- .ee_mask_landsat_qa(img)

    # Scale reflectance bands first, then compute NDVI
    b5 <- .ee_select(img_masked, "SR_B5")
    b5_scaled <- .ee_scale_offset(b5, meta$scale_factor, meta$offset)
    b4 <- .ee_select(img_masked, "SR_B4")
    b4_scaled <- .ee_scale_offset(b4, meta$scale_factor, meta$offset)

    # NDVI = (NIR - Red) / (NIR + Red)
    numerator <- .ee_call(
      "Image.subtract",
      image1 = b5_scaled,
      image2 = b4_scaled
    )
    denominator <- .ee_call("Image.add", image1 = b5_scaled, image2 = b4_scaled)
    ndvi <- .ee_call("Image.divide", image1 = numerator, image2 = denominator)

    .rest_extract_raster_expr(
      ndvi,
      region,
      meta,
      NULL,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ===========================================================================
# Generic handler for registered + built-in simple datasets
# ===========================================================================

#' Generic handler using only metadata fields
#'
#' Works for any dataset where extraction is: load -> filter -> select -> scale.
#' No dataset-specific QA masking. Used for user-registered datasets and
#' simple built-in collections (WorldClim, OpenLandMap, etc.).
#'
#' @noRd
.read_gee_generic <- function(dots, did, backend, max_tries, initial_delay) {
  meta <- .gee_combined_meta()[[did]]
  if (is.null(meta)) {
    cli::cli_abort("No metadata found for dataset {.val {did}}.")
  }

  # Inform user that generic handler applies no QA masking
  cli::cli_inform(c(
    "i" = "Using generic handler for {.val {did}} (no QA masking applied)."
  ))

  date <- if (meta$temporal != "static") {
    .validate_date(dots$date, "date", did)
  } else {
    NULL
  }
  region <- .validate_region(dots$region)

  if (backend == "rest") {
    if (meta$temporal == "static") {
      img <- .ee_load_image(meta$collection)
    } else {
      date_end <- switch(
        meta$temporal,
        daily = date + 1L,
        "8day" = date + 8L,
        "16day" = date + 16L,
        "5day" = date + 5L,
        monthly = lubridate::ceiling_date(date, "month"),
        date + 1L
      )
      col <- .ee_load_collection(meta$collection)
      col_filtered <- .ee_filter_date(col, date, date_end)
      img <- .ee_first(col_filtered)
    }

    # Allow user to override bands via variable arg (e.g., WorldClim bio01-bio19)
    bands <- dots$variable %||% meta$bands
    img_band <- .ee_select(img, bands)
    img_scaled <- .ee_scale_offset(img_band, meta$scale_factor, meta$offset)

    .rest_extract_raster_expr(
      img_scaled,
      region,
      meta,
      bands,
      max_tries,
      initial_delay
    )
  } else {
    .rgee_extract(meta, date, region, max_tries, initial_delay)
  }
}


# ---- Fallback: rgee backend (Suggests-guarded) ----

#' Generic rgee extraction fallback
#' @noRd
.rgee_extract <- function(meta, date, region, max_tries, initial_delay) {
  if (!rlang::is_installed("rgee")) {
    cli::cli_abort(c(
      "The {.pkg rgee} package is required for {.code backend = \"rgee\"}.",
      "i" = "Install with: {.code install.packages(\"rgee\")}",
      "i" = "Or use {.code backend = \"rest\"} (default, no Python needed)."
    ))
  }
  cli::cli_abort(c(
    "rgee backend handlers are not yet implemented.",
    "i" = "Use {.code backend = \"rest\"} (default) for now."
  ))
}
