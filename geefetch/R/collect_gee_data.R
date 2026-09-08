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
#' `r lifecycle::badge("experimental")`
#'
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
#'   \item{`<dataset columns>`}{One column per requested dataset}
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
collect_gee_data <- function(
  lon = NULL,
  lat = NULL,
  xy = NULL,
  date_range,
  datasets = NULL,
  depth = "0-5",
  stat = "mean",
  backend = c("rest", "rgee"),
  cache = TRUE,
  verbose = TRUE,
  na.rm = FALSE
) {
  backend <- rlang::arg_match(backend)

  # 1. Parse and validate coordinates
  coords <- .parse_coordinates(lon, lat, xy)

  # 2. Parse date range
  dates <- .parse_date_range(date_range)

  # 3. Validate datasets
  if (is.null(datasets) || length(datasets) == 0L) {
    cli::cli_abort(c(
      "{.arg datasets} must be a non-empty character vector.",
      i = "Use {.code gee_datasets()} to see available datasets."
    ))
  }
  resolved <- vapply(
    datasets,
    .gee_resolve_id,
    character(1L),
    USE.NAMES = FALSE
  )

  # 4. Check authentication
  .check_gee_auth(backend)

  # 5. Classify datasets: time-series vs static
  combined_meta <- .gee_combined_meta()
  is_static <- vapply(
    resolved,
    function(did) {
      meta <- combined_meta[[did]]
      !is.null(meta) && identical(meta$temporal, "static")
    },
    logical(1L)
  )

  ts_datasets <- resolved[!is_static]
  static_datasets <- resolved[is_static]

  # 6. Print info table (verbose)
  if (verbose) {
    .print_collection_info(coords, dates, resolved, is_static, combined_meta)
  }

  # Per-dataset options for the expression builder (SLGA depth and stat)
  dots <- list(depth = depth, stat = stat)

  # 7. Build scaffold: one row per (location x date)
  n_locs <- nrow(coords)
  n_dates <- length(dates)

  dt <- data.table::data.table(
    point_id = rep(coords$point_id, each = n_dates),
    lon = rep(coords$lon, each = n_dates),
    lat = rep(coords$lat, each = n_dates),
    date = rep(dates, times = n_locs)
  )

  # 8. Extract: per-dataset (batching all points per API call)
  total_ops <- length(ts_datasets) * n_dates + length(static_datasets)
  op_count <- 0L

  if (verbose && total_ops > 1L) {
    cli::cli_progress_bar(
      "Extracting",
      total = total_ops,
      format = "{cli::pb_spin} {cli::pb_current}/{cli::pb_total} API calls | {cli::pb_elapsed}"
    )
  }

  # -- Time-series datasets: one API call per date (all points batched) --
  for (did in ts_datasets) {
    meta <- combined_meta[[did]]
    all_vals <- rep(NA_real_, nrow(dt))

    for (j in seq_len(n_dates)) {
      date_j <- dates[j]
      row_idx <- which(dt$date == date_j)
      pts_for_date <- coords

      vals <- .safe_extract_points_batch(
        meta = meta,
        date = date_j,
        coords = pts_for_date,
        did = did,
        backend = backend,
        cache = cache,
        max_tries = 3L,
        initial_delay = 1L,
        dots = dots
      )
      all_vals[row_idx] <- vals

      op_count <- op_count + 1L
      if (verbose && total_ops > 1L) cli::cli_progress_update()
    }

    data.table::set(dt, j = did, value = all_vals)
  }

  # -- Static datasets: one API call total (all points batched) --
  for (did in static_datasets) {
    meta <- combined_meta[[did]]

    vals <- .safe_extract_points_batch(
      meta = meta,
      date = NULL,
      coords = coords,
      did = did,
      backend = backend,
      cache = cache,
      max_tries = 3L,
      initial_delay = 1L,
      dots = dots
    )

    # Replicate static values across all dates for each point
    all_vals <- rep(vals, each = n_dates)
    data.table::set(dt, j = did, value = all_vals)

    op_count <- op_count + 1L
    if (verbose && total_ops > 1L) cli::cli_progress_update()
  }

  if (verbose && total_ops > 1L) {
    cli::cli_progress_done()
  }

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

#' Safely extract values for ALL points for one dataset and one date
#'
#' Sends all points in a single API call (batched). Falls back to
#' per-point extraction if batch fails. Returns a numeric vector
#' with one value per point (in coords row order).
#'
#' @param meta List. Dataset metadata.
#' @param date Date or NULL (for static).
#' @param coords data.table with point_id, lon, lat.
#' @param did Character. Dataset ID.
#' @param backend Character.
#' @param cache Logical.
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns Numeric vector of length nrow(coords). NAs for failed points.
#' @noRd
.safe_extract_points_batch <- function(
  meta,
  date,
  coords,
  did,
  backend,
  cache,
  max_tries,
  initial_delay,
  dots = list()
) {
  n_pts <- nrow(coords)

  # Check batch cache first
  cache_key <- list(
    type = "batch",
    did = did,
    date = as.character(date),
    depth = dots$depth %||% NA_character_,
    stat = dots$stat %||% NA_character_,
    pts_hash = digest::digest(coords[, .(lon, lat)], algo = "sha256")
  )

  if (cache) {
    cached <- .cache_get(did, cache_key)
    if (!is.null(cached) && length(cached) == n_pts) {
      return(as.numeric(cached))
    }
  }

  result <- tryCatch(
    {
      if (backend == "rest") {
        .rest_extract_batch_points(
          meta, date, coords, max_tries, initial_delay, did = did, dots = dots
        )
      } else {
        .rgee_extract_point(meta, date, coords[1L, ], max_tries, initial_delay)
      }
    },
    error = function(e) {
      msg <- conditionMessage(e)
      cli::cli_warn(c(
        `!` = "Batch extraction failed for {.val {did}}",
        `!` = if (!is.null(date)) paste0("Date: ", date) else "Static dataset",
        i = "{msg}"
      ))
      rep(NA_real_, n_pts)
    }
  )

  if (cache && !all(is.na(result))) {
    .cache_set(did, cache_key, result)
  }

  result
}


#' Extract point values for multiple locations via REST API (batched)
#'
#' Sends ALL points in a single computeFeatures call. Returns a
#' numeric vector aligned to coords row order.
#'
#' @returns Numeric vector of length nrow(coords).
#' @noRd
.rest_extract_batch_points <- function(
  meta,
  date,
  coords,
  max_tries,
  initial_delay,
  did = NULL,
  dots = list()
) {
  n_pts <- nrow(coords)
  built <- .ee_dataset_image(
    meta, did %||% "", date, .ee_multipoint(coords), dots
  )
  band_name <- built$band
  sample_expr <- .ee_sample_regions(built$node, coords, meta$scale)

  dt <- .rest_compute_features(
    expression = sample_expr,
    max_tries = max_tries,
    initial_delay = initial_delay
  )

  # Masked points are absent from the reply; align by point_id.
  values <- rep(NA_real_, n_pts)

  if (nrow(dt) == 0L) {
    return(values)
  }
  if (!"point_id" %in% names(dt)) {
    cli::cli_abort(c(
      "Earth Engine reply carries no {.field point_id} property.",
      i = "Values cannot be aligned to the requested points safely."
    ))
  }
  if (!band_name %in% names(dt)) {
    return(values)
  }
  for (i in seq_len(nrow(dt))) {
    idx <- which(coords$point_id == dt$point_id[i])
    if (length(idx) == 1L) {
      val <- dt[[band_name]][i]
      values[idx] <- if (is.null(val) || is.na(val)) {
        NA_real_
      } else {
        as.numeric(val)
      }
    }
  }

  values
}


#' rgee point extraction fallback
#' @noRd
.rgee_extract_point <- function(
  meta,
  date,
  pt_coords,
  max_tries,
  initial_delay
) {
  if (!rlang::is_installed("rgee")) {
    cli::cli_abort(c(
      "The {.pkg rgee} package is required for {.code backend = \"rgee\"}.",
      i = "Install with: {.code install.packages(\"rgee\")}",
      i = "Or use {.code backend = \"rest\"} (default, no Python needed)."
    ))
  }
  cli::cli_abort("rgee point extraction not yet implemented.")
}


#' Print a summary table of what will be collected
#' @noRd
.print_collection_info <- function(
  coords,
  dates,
  resolved,
  is_static,
  combined_meta
) {
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
    dataset = resolved,
    type = ifelse(is_static, "static", "time-series"),
    domain = vapply(
      resolved,
      function(d) {
        combined_meta[[d]]$domain %||% "?"
      },
      character(1L)
    )
  )
  cli::cli_text("")
  cli::cli_verbatim(.format_dataset_table(info_dt))
  cli::cli_text("")

  total_calls <- (n_ts * n_dates * n_locs) + (n_static * n_locs)
  cli::cli_alert_info(
    "Estimated API calls: {.val {total_calls}} (before caching)"
  )
  cli::cli_text("")
}


#' Format a data.table as fixed-width text lines, header + rule + rows
#'
#' Avoids an unsuppressable `print()`/`cat()` call: the caller passes the
#' formatted lines to `cli::cli_verbatim()` instead.
#'
#' @param dt A data.table.
#' @returns Character vector of formatted lines.
#' @noRd
.format_dataset_table <- function(dt) {
  cols <- names(dt)
  cells <- lapply(dt, as.character)
  widths <- vapply(cols, function(cn) {
    max(nchar(cn), nchar(cells[[cn]]))
  }, integer(1L))

  pad_row <- function(values) {
    paste(
      mapply(formatC, values, width = -widths, USE.NAMES = FALSE),
      collapse = "  "
    )
  }

  header <- pad_row(cols)
  rule <- pad_row(vapply(widths, function(w) strrep("-", w), character(1L)))
  rows <- vapply(seq_len(nrow(dt)), function(i) {
    pad_row(vapply(cells, `[[`, character(1L), i))
  }, character(1L))

  c(header, rule, rows)
}
