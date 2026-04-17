# utils.R — Input validation and parsing utilities
#
# All internal. Used by the dispatcher, batch extraction, and handlers.
# Error messages follow nert's pattern: cli::cli_abort() with context.

# ---- Date validation & parsing ----

#' Validate and parse a single date
#'
#' @param date Character, Date, or POSIXt. The date to validate.
#' @param arg_name Character. Name of the argument (for error messages).
#' @param dataset_id Character. Dataset ID (for date range checking).
#'
#' @returns A Date object.
#'
#' @noRd
.validate_date <- function(date, arg_name = "date", dataset_id = NULL) {
  if (is.null(date)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} is required for this dataset.",
      "i" = "Provide a date as {.val YYYY-MM-DD} character or a Date object."
    ))
  }

  parsed <- tryCatch(
    lubridate::as_date(date),
    error = function(e) NULL,
    warning = function(w) NULL
  )

  if (is.null(parsed) || is.na(parsed)) {
    cli::cli_abort(c(
      "Cannot parse {.arg {arg_name}} = {.val {date}} as a date.",
      "i" = "Expected format: {.val YYYY-MM-DD} (e.g., {.val 2024-06-15})."
    ))
  }

  # Check against dataset date range if metadata available

  if (!is.null(dataset_id)) {
    meta <- .gee_combined_meta()[[dataset_id]]
    if (!is.null(meta) && !is.na(meta$date_start)) {
      ds <- lubridate::as_date(meta$date_start)
      if (parsed < ds) {
        cli::cli_abort(c(
          "Date {.val {parsed}} is before {.val {dataset_id}} availability.",
          "i" = "Earliest available date: {.val {ds}}."
        ))
      }
    }
    if (!is.null(meta) && !is.na(meta$date_end)) {
      de <- lubridate::as_date(meta$date_end)
      if (parsed > de) {
        cli::cli_abort(c(
          "Date {.val {parsed}} is after {.val {dataset_id}} availability.",
          "i" = "Latest available date: {.val {de}}."
        ))
      }
    }
  }

  parsed
}


#' Parse a date range into a sequence of dates
#'
#' @param date_range A length-2 character/Date vector (start, end),
#'   or an explicit vector of dates.
#'
#' @returns A vector of Date objects.
#'
#' @noRd
.parse_date_range <- function(date_range) {
  if (is.null(date_range) || length(date_range) == 0L) {
    cli::cli_abort(c(
      "{.arg date_range} must not be empty.",
      "i" = "Provide {.code c(start, end)} or an explicit date vector."
    ))
  }

  # Parse all elements to Date
  dates <- tryCatch(
    lubridate::as_date(date_range),
    error = function(e) NULL,
    warning = function(w) NULL
  )

  if (is.null(dates) || any(is.na(dates))) {
    cli::cli_abort(c(
      "Cannot parse {.arg date_range} as dates.",
      "i" = "Expected format: {.val YYYY-MM-DD}.",
      "i" = "Example: {.code c(\"2024-01-01\", \"2024-12-31\")}"
    ))
  }

  # If exactly 2 dates, expand to daily sequence

  if (length(dates) == 2L) {
    if (dates[1L] > dates[2L]) {
      cli::cli_abort(c(
        "Start date {.val {dates[1L]}} is after end date {.val {dates[2L]}}.",
        "i" = "Provide dates in chronological order."
      ))
    }
    dates <- seq.Date(dates[1L], dates[2L], by = "day")
  }

  sort(unique(dates))
}


# ---- Coordinate validation & parsing ----

#' Validate a single coordinate value
#'
#' @param value Numeric. The coordinate.
#' @param name Character. `"lon"` or `"lat"`.
#'
#' @returns Numeric (validated).
#'
#' @noRd
.validate_single_coord <- function(value, name = "lon") {
  if (!is.numeric(value) || length(value) != 1L || is.na(value)) {
    cli::cli_abort("{.arg {name}} must be a single non-NA numeric value.")
  }

  limits <- if (name %in% c("lon", "x", "longitude")) {
    c(-180, 180)
  } else {
    c(-90, 90)
  }

  if (value < limits[1L] || value > limits[2L]) {
    cli::cli_abort(c(
      "{.arg {name}} = {.val {value}} is out of range.",
      "i" = "Valid range: [{limits[1L]}, {limits[2L]}]."
    ))
  }

  value
}


#' Parse coordinates from various input formats
#'
#' Accepts lon/lat vectors, xy data.frame/matrix, or sf object.
#' Returns a data.table with `lon` and `lat` columns.
#'
#' @param lon Numeric vector or NULL.
#' @param lat Numeric vector or NULL.
#' @param xy data.frame, matrix, sf, or NULL.
#'
#' @returns A data.table with columns `lon`, `lat`, and `point_id`.
#'
#' @noRd
.parse_coordinates <- function(lon = NULL, lat = NULL, xy = NULL) {
  # Case 1: sf object
  if (!is.null(xy) && inherits(xy, "sf")) {
    if (!all(sf::st_geometry_type(xy) %in% c("POINT", "MULTIPOINT"))) {
      cli::cli_abort(c(
        "{.arg xy} must contain POINT geometries.",
        "i" = "Got geometry type(s): {.val {unique(sf::st_geometry_type(xy))}}."
      ))
    }
    # Transform to WGS84 if needed
    if (sf::st_crs(xy) != sf::st_crs(4326)) {
      xy <- sf::st_transform(xy, 4326)
    }
    coords <- sf::st_coordinates(xy)
    dt <- data.table::data.table(
      point_id = seq_len(nrow(coords)),
      lon = coords[, 1L],
      lat = coords[, 2L]
    )
    return(dt)
  }

  # Case 2: data.frame or matrix with lon/lat or x/y columns
  if (!is.null(xy)) {
    if (is.matrix(xy)) {
      xy <- as.data.frame(xy)
    }
    if (!is.data.frame(xy)) {
      cli::cli_abort("{.arg xy} must be a data.frame, matrix, or sf object.")
    }
    col_names <- tolower(names(xy))
    if ("lon" %in% col_names && "lat" %in% col_names) {
      lon_col <- names(xy)[col_names == "lon"]
      lat_col <- names(xy)[col_names == "lat"]
    } else if ("x" %in% col_names && "y" %in% col_names) {
      lon_col <- names(xy)[col_names == "x"]
      lat_col <- names(xy)[col_names == "y"]
    } else if ("longitude" %in% col_names && "latitude" %in% col_names) {
      lon_col <- names(xy)[col_names == "longitude"]
      lat_col <- names(xy)[col_names == "latitude"]
    } else {
      cli::cli_abort(c(
        "{.arg xy} must have columns named {.val lon}/{.val lat}, ",
        "{.val x}/{.val y}, or {.val longitude}/{.val latitude}.",
        "i" = "Found columns: {.val {names(xy)}}."
      ))
    }
    lon <- xy[[lon_col]]
    lat <- xy[[lat_col]]
  }

  # Case 3: explicit lon/lat vectors
  if (is.null(lon) || is.null(lat)) {
    cli::cli_abort(c(
      "No coordinates provided.",
      "i" = "Provide {.arg lon} and {.arg lat} vectors, or an {.arg xy} object."
    ))
  }

  if (length(lon) != length(lat)) {
    cli::cli_abort("{.arg lon} and {.arg lat} must have the same length.")
  }

  # Validate all coordinates
  for (i in seq_along(lon)) {
    .validate_single_coord(lon[i], "lon")
    .validate_single_coord(lat[i], "lat")
  }

  data.table::data.table(
    point_id = seq_along(lon),
    lon = as.numeric(lon),
    lat = as.numeric(lat)
  )
}


# ---- Dataset validation ----

#' Validate that a dataset ID exists in the registry
#'
#' @param dataset_id Character. Normalised dataset ID.
#'
#' @returns The validated ID (invisibly). Aborts on failure.
#'
#' @noRd
.validate_dataset <- function(dataset_id) {
  combined <- .gee_combined_meta()
  if (!dataset_id %in% names(combined)) {
    .gee_not_implemented(dataset_id)
  }
  invisible(dataset_id)
}


# ---- Region / extent validation ----

#' Validate and normalise a spatial region argument
#'
#' @param region An sf/sfc object, terra::ext, or NULL.
#'
#' @returns An sf/sfc polygon in WGS84, or NULL.
#'
#' @noRd
.validate_region <- function(region) {
  if (is.null(region)) {
    return(NULL)
  }

  if (inherits(region, "SpatExtent")) {
    # Convert terra extent to sf bbox polygon
    region <- sf::st_as_sfc(sf::st_bbox(
      c(
        xmin = terra::xmin(region),
        ymin = terra::ymin(region),
        xmax = terra::xmax(region),
        ymax = terra::ymax(region)
      ),
      crs = sf::st_crs(4326)
    ))
  }

  if (!inherits(region, c("sf", "sfc"))) {
    cli::cli_abort(c(
      "{.arg region} must be an {.cls sf}, {.cls sfc}, or {.cls SpatExtent} object.",
      "i" = "Got class: {.val {class(region)}}."
    ))
  }

  # Transform to WGS84 if needed
  if (!is.na(sf::st_crs(region)) && sf::st_crs(region) != sf::st_crs(4326)) {
    region <- sf::st_transform(region, 4326)
  }

  region
}


# ---- Argument validation for the dispatcher ----

#' Pre-API-call validation of handler arguments
#'
#' Checks that required arguments are present and valid for a given dataset.
#' This runs before any network call, so users get fast feedback on input errors.
#'
#' @param did Character. Normalised dataset ID.
#' @param dots Named list of user-supplied arguments.
#'
#' @returns NULL (invisibly). Aborts on validation failure.
#'
#' @noRd
.gee_validate_args <- function(did, dots) {
  meta <- .gee_combined_meta()[[did]]
  if (is.null(meta)) {
    return(invisible(NULL))
  }

  # Time-series datasets require a date

  if (!identical(meta$temporal, "static")) {
    if (is.null(dots$date)) {
      cli::cli_abort(c(
        "Dataset {.val {did}} requires a {.arg date} argument.",
        "i" = "Example: {.code read_gee(\"{did}\", date = \"2024-06-15\")}"
      ))
    }
    .validate_date(dots$date, "date", did)
  }

  # SLGA-specific: validate depth and stat if provided
  if (startsWith(did, "slga_")) {
    if (!is.null(dots$depth)) {
      valid_depths <- c(
        "0-5",
        "5-15",
        "15-30",
        "30-60",
        "60-100",
        "100-200",
        "all"
      )
      if (!dots$depth %in% valid_depths) {
        cli::cli_abort(c(
          "Invalid {.arg depth} = {.val {dots$depth}} for SLGA dataset.",
          "i" = "Valid depths: {.val {valid_depths}}."
        ))
      }
    }
    if (!is.null(dots$stat)) {
      valid_stats <- c("mean", "ci_lower", "ci_upper")
      if (!dots$stat %in% valid_stats) {
        cli::cli_abort(c(
          "Invalid {.arg stat} = {.val {dots$stat}} for SLGA dataset.",
          "i" = "Valid stats: {.val {valid_stats}}."
        ))
      }
    }
  }

  invisible(NULL)
}
