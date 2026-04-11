# collect_gee_data.R — Batch extraction across locations, dates, and datasets
#
# Follows nert's collect_tern_data() pattern:
#   1. Parse coordinates (lon/lat, xy, sf)
#   2. Parse date range
#   3. Validate datasets
#   4. Print info table (verbose)
#   5. Per-location: .collect_single_location()
#   6. Bind into wide data.table

#' Batch-extract GEE data at point locations
#'
#' @description
#' Extracts values from multiple GEE datasets at one or more point
#' locations across a date range. Returns a single [data.table::data.table]
#' with one row per location-date combination and one column per dataset.
#'
#' This is the primary function for building environmental covariate
#' tables for modelling.
#'
#' @param lon,lat Numeric vectors of coordinates (WGS84). Ignored if
#'   `xy` is provided.
#' @param xy A data.frame, matrix, or [sf::sf] object with point
#'   locations. Must contain columns named `lon`/`lat`, `x`/`y`,
#'   or `longitude`/`latitude`, or be an sf POINT geometry.
#' @param date_range A length-2 character or Date vector (`c(start, end)`),
#'   or an explicit vector of dates.
#' @param datasets Character vector of dataset names or aliases.
#'   Use [gee_datasets()] to list available options.
#' @param depth Character. For SLGA soil datasets: depth layer(s).
#'   `"0-5"`, `"5-15"`, ..., `"100-200"`, or `"all"`. Default `"0-5"`.
#' @param stat Character. For SLGA soil datasets: statistic.
#'   `"mean"`, `"ci_lower"`, `"ci_upper"`. Default `"mean"`.
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Default `TRUE`.
#' @param verbose Logical. Print progress table and status messages?
#'   Default `TRUE`.
#' @param na.rm Logical. Remove rows where all dataset columns are NA?
#'   Default `FALSE`.
#'
#' @returns A [data.table::data.table] with columns:
#' \describe{
#'   \item{date}{Date of extraction}
#'   \item{lon, lat}{Coordinates (always included)}
#'   \item{point_id}{Integer point identifier}
#'   \item{<dataset columns>}{One column per requested dataset}
#' }
#'
#' @section Column naming:
#' Each dataset produces a column named after its normalised ID
#' (e.g., `modis_ndvi`, `era5_temp`, `srtm_elevation`). Static
#' datasets have their value replicated across all dates.
#'
#' @section Error handling:
#' Failed extractions for individual dataset-date combinations produce
#' `NA` values with a warning. Execution continues for remaining
#' datasets. This matches `nert`'s resilient batch behaviour.
#'
#' @family GEE batch
#' @seealso [read_gee()] for single-dataset reads,
#'   [gee_datasets()] to list available datasets.
#'
#' @examplesIf interactive()
#' # Single location, multiple datasets
#' dt <- collect_gee_data(
#'   lon = 138.6, lat = -34.9,
#'   date_range = c("2024-01-01", "2024-03-31"),
#'   datasets = c("modis_ndvi", "era5_temp")
#' )
#'
#' # Multiple locations from a data.frame
#' sites <- data.frame(lon = c(138.6, 149.1), lat = c(-34.9, -35.3))
#' dt <- collect_gee_data(
#'   xy = sites,
#'   date_range = c("2024-01-01", "2024-12-31"),
#'   datasets = c("modis_ndvi", "era5_temp", "srtm_elevation")
#' )
#'
#' @export
collect_gee_data <- function(lon = NULL, lat = NULL,
                             xy = NULL,
                             date_range,
                             datasets = NULL,
                             depth = "0-5",
                             stat = "mean",
                             backend = c("rest", "rgee"),
                             cache = TRUE,
                             verbose = TRUE,
                             na.rm = FALSE) {

  backend <- match.arg(backend)

  # 1. Parse and validate coordinates
  coords <- .parse_coordinates(lon, lat, xy)

  # 2. Parse date range
  dates <- .parse_date_range(date_range)

  # 3. Validate datasets
  if (is.null(datasets) || length(datasets) == 0L) {
    cli::cli_abort(c(
      "{.arg datasets} must be a non-empty character vector.",
      "i" = "Use {.code gee_datasets()} to see available datasets."
    ))
  }
  resolved <- vapply(datasets, .gee_resolve_id, character(1L),
                     USE.NAMES = FALSE)

  # 4. Check authentication
  .check_gee_auth(backend)

  # 5. Classify datasets: time-series vs static
  combined_meta <- .gee_combined_meta()
  is_static <- vapply(resolved, function(did) {
    meta <- combined_meta[[did]]
    !is.null(meta) && identical(meta$temporal, "static")
  }, logical(1L))

  ts_datasets     <- resolved[!is_static]
  static_datasets <- resolved[is_static]

  # 6. Print info table (verbose)
  if (verbose) {
    .print_collection_info(coords, dates, resolved, is_static, combined_meta)
  }

  # 7. Extract: per-location
  n_locs <- nrow(coords)
  all_results <- vector("list", n_locs)

  if (verbose && n_locs > 1L) {
    cli::cli_progress_bar(
      "Extracting",
      total = n_locs,
      format = "{cli::pb_spin} Extracting location {cli::pb_current}/{cli::pb_total} | {cli::pb_elapsed}"
    )
  }

  for (i in seq_len(n_locs)) {
    pt_coords <- coords[i, ]

    all_results[[i]] <- .collect_single_location(
      pt_coords       = pt_coords,
      dates           = dates,
      ts_datasets     = ts_datasets,
      static_datasets = static_datasets,
      combined_meta   = combined_meta,
      backend         = backend,
      cache           = cache,
      max_tries       = 3L,
      initial_delay   = 1
    )

    if (verbose && n_locs > 1L) {
      cli::cli_progress_update()
    }
  }

  if (verbose && n_locs > 1L) {
    cli::cli_progress_done()
  }

  # 8. Bind all locations
  dt <- data.table::rbindlist(all_results, fill = TRUE)

  # 9. Set column order: point_id, lon, lat, date, then datasets
  id_cols <- c("point_id", "lon", "lat", "date")
  dataset_cols <- intersect(resolved, names(dt))
  col_order <- intersect(c(id_cols, dataset_cols), names(dt))
  data.table::setcolorder(dt, col_order)

  # 10. Optionally remove all-NA rows
  if (na.rm && length(dataset_cols) > 0L) {
    all_na <- dt[, Reduce(`&`, lapply(.SD, is.na)), .SDcols = dataset_cols]
    dt <- dt[!all_na]
  }

  dt[]
}


# ===========================================================================
# Internal helpers
# ===========================================================================

#' Extract data for a single location across all dates and datasets
#'
#' @param pt_coords data.table row with point_id, lon, lat.
#' @param dates Date vector.
#' @param ts_datasets Character vector of time-series dataset IDs.
#' @param static_datasets Character vector of static dataset IDs.
#' @param combined_meta Named list of all dataset metadata.
#' @param backend Character.
#' @param cache Logical.
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns A data.table with one row per date.
#' @noRd
.collect_single_location <- function(pt_coords,
                                     dates,
                                     ts_datasets,
                                     static_datasets,
                                     combined_meta,
                                     backend,
                                     cache,
                                     max_tries,
                                     initial_delay) {

  n_dates <- length(dates)

  # Scaffold: one row per date with point info
  dt <- data.table::data.table(
    point_id = rep(pt_coords$point_id, n_dates),
    lon      = rep(pt_coords$lon, n_dates),
    lat      = rep(pt_coords$lat, n_dates),
    date     = dates
  )

  # -- Time-series datasets: extract per date --
  for (did in ts_datasets) {
    meta <- combined_meta[[did]]
    values <- rep(NA_real_, n_dates)

    for (j in seq_len(n_dates)) {
      values[j] <- .safe_extract_point(
        meta          = meta,
        date          = dates[j],
        pt_coords     = pt_coords,
        did           = did,
        backend       = backend,
        cache         = cache,
        max_tries     = max_tries,
        initial_delay = initial_delay
      )
    }

    data.table::set(dt, j = did, value = values)
  }

  # -- Static datasets: extract once, replicate --
  for (did in static_datasets) {
    meta <- combined_meta[[did]]
    single_val <- .safe_extract_point(
      meta          = meta,
      date          = NULL,
      pt_coords     = pt_coords,
      did           = did,
      backend       = backend,
      cache         = cache,
      max_tries     = max_tries,
      initial_delay = initial_delay
    )

    data.table::set(dt, j = did, value = rep(single_val, n_dates))
  }

  dt
}


#' Safely extract a single point value for one dataset and date
#'
#' Wraps the REST point extraction in tryCatch. Returns NA with a
#' warning on failure (nert's resilient batch pattern).
#'
#' @returns Numeric value or NA_real_.
#' @noRd
.safe_extract_point <- function(meta, date, pt_coords, did,
                                backend, cache, max_tries, initial_delay) {

  # Build cache key for point extraction
  cache_key <- list(
    type    = "point",
    did     = did,
    lon     = pt_coords$lon,
    lat     = pt_coords$lat,
    date    = as.character(date)
  )

  if (cache) {
    cached <- .cache_get(did, cache_key)
    if (!is.null(cached)) return(as.numeric(cached))
  }

  result <- tryCatch({
    if (backend == "rest") {
      .rest_extract_single_point(meta, date, pt_coords, max_tries, initial_delay)
    } else {
      .rgee_extract_point(meta, date, pt_coords, max_tries, initial_delay)
    }
  }, error = function(e) {
    cli::cli_warn(c(
      "!" = "Extraction failed for {.val {did}} at ({pt_coords$lon}, {pt_coords$lat})",
      "!" = if (!is.null(date)) paste0("Date: ", date) else "Static dataset",
      "i" = conditionMessage(e)
    ))
    NA_real_
  })

  if (cache && !is.na(result)) {
    .cache_set(did, cache_key, result)
  }

  result
}


#' Extract a single point value via REST API
#'
#' Builds the expression for one point and one date, calls computeFeatures.
#'
#' @returns Numeric value or NA_real_.
#' @noRd
.rest_extract_single_point <- function(meta, date, pt_coords,
                                       max_tries, initial_delay) {

  bands <- meta$bands

  # Build image expression
  if (meta$temporal == "static") {
    img <- .ee_load_image(meta$collection)
  } else {
    date_end <- switch(meta$temporal,
      daily   = date + 1L,
      "8day"  = date + 8L,
      "16day" = date + 16L,
      "5day"  = date + 5L,
      monthly = lubridate::ceiling_date(date, "month"),
      date + 1L
    )
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date, date_end)
    img <- .ee_first(col_filtered)
  }

  # Apply QA masking for MODIS datasets
  if (grepl("^MODIS/061/MOD13", meta$collection)) {
    img <- .ee_mask_modis_vi(img)
  } else if (grepl("^MODIS/061/MOD11", meta$collection)) {
    img <- .ee_mask_modis_lst(img)
  }

  img <- .ee_select(img, bands)
  img <- .ee_scale_offset(img, meta$scale_factor, meta$offset)

  # Build single-point GeoJSON
  geojson <- .coords_to_geojson(pt_coords)
  sample_expr <- .ee_sample_regions(img, geojson, meta$scale)

  dt <- .rest_compute_features(
    expression    = sample_expr,
    max_tries     = max_tries,
    initial_delay = initial_delay
  )

  if (nrow(dt) == 0L) return(NA_real_)

  # Extract the first band value
  band_name <- if (length(bands) == 1L) bands else bands[1L]
  if (band_name %in% names(dt)) {
    val <- dt[[band_name]][1L]
    if (is.null(val) || is.na(val)) NA_real_ else as.numeric(val)
  } else {
    NA_real_
  }
}


#' rgee point extraction fallback
#' @noRd
.rgee_extract_point <- function(meta, date, pt_coords,
                                max_tries, initial_delay) {
  if (!rlang::is_installed("rgee")) {
    cli::cli_abort(c(
      "The {.pkg rgee} package is required for {.code backend = \"rgee\"}.",
      "i" = "Install with: {.code install.packages(\"rgee\")}",
      "i" = "Or use {.code backend = \"rest\"} (default, no Python needed)."
    ))
  }
  cli::cli_abort("rgee point extraction not yet implemented.")
}


#' Print a summary table of what will be collected
#' @noRd
.print_collection_info <- function(coords, dates, resolved, is_static,
                                   combined_meta) {
  n_locs <- nrow(coords)
  n_dates <- length(dates)
  n_ts <- sum(!is_static)
  n_static <- sum(is_static)

  cli::cli_h2("collect_gee_data")
  cli::cli_alert_info(
    "Locations: {.val {n_locs}} | Dates: {.val {n_dates}} ({dates[1]} to {dates[n_dates]})"
  )
  cli::cli_alert_info(
    "Datasets: {.val {length(resolved)}} ({n_ts} time-series, {n_static} static)"
  )

  # Dataset table
  info_dt <- data.table::data.table(
    dataset  = resolved,
    type     = ifelse(is_static, "static", "time-series"),
    domain   = vapply(resolved, function(d) {
      combined_meta[[d]]$domain %||% "?"
    }, character(1L))
  )
  cli::cli_text("")
  print(info_dt, topn = 20L)
  cli::cli_text("")

  total_calls <- (n_ts * n_dates * n_locs) + (n_static * n_locs)
  cli::cli_alert_info(
    "Estimated API calls: {.val {total_calls}} (before caching)"
  )
  cli::cli_text("")
}
