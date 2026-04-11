# backend_rest.R — GEE REST API extraction engine
#
# Direct HTTP access to Google Earth Engine via httr2 + gargle.
# No Python. No reticulate. Pure R.
#
# Architecture:
#   1. Expression builder (.ee_*) — constructs GEE computation graph as JSON
#   2. Request functions (.rest_request, .rest_compute_*) — send to REST API
#   3. Extraction functions (.rest_extract_*) — high-level: build expr + request + parse

#' @importFrom httr2 request req_headers req_body_json req_perform
#'   req_retry resp_body_json resp_status resp_body_raw
#' @importFrom jsonlite fromJSON toJSON
NULL


# ===========================================================================
# Section 1: Constants
# ===========================================================================

#' Base URL for the GEE REST API
#' @noRd
.GEE_REST_BASE <- "https://earthengine.googleapis.com/v1"


# ===========================================================================
# Section 1b: Token management helpers
# ===========================================================================

#' Refresh a gargle token if it's near expiry
#'
#' gargle tokens expire after 3600 seconds. For long-running batch
#' jobs, we need to refresh before each request.
#'
#' @param token A gargle token object or raw string.
#' @returns The (possibly refreshed) token.
#' @noRd
.maybe_refresh_token <- function(token) {
  # Only refresh real gargle tokens, not test strings
  if (inherits(token, "Token2.0") || inherits(token, "request")) {
    tryCatch({
      if (is.function(token$refresh)) token$refresh()
    }, error = function(e) {
      # Refresh failed — token may still be valid, proceed
    })
  }
  # Update stored token
  .geefetch_env$token <- token
  token
}

#' Extract access token string from token object
#'
#' Handles gargle Token2.0 objects, httr tokens, and raw strings.
#'
#' @param token Token object or character string.
#' @returns Character. Access token string.
#' @noRd
.extract_access_token <- function(token) {
  if (is.character(token)) return(token)
  if (!is.null(token$credentials$access_token)) {
    return(token$credentials$access_token)
  }
  if (!is.null(token$auth_token$credentials$access_token)) {
    return(token$auth_token$credentials$access_token)
  }
  # Fallback: try to use as-is
  as.character(token)
}


# ===========================================================================
# Section 2: Expression builder utilities
# ===========================================================================
# These construct the GEE computation graph as nested R lists, which
# are then serialised to JSON for the REST API.
#
# The GEE REST API uses an expression DAG (directed acyclic graph):
#   { "result": "0", "values": { "0": <ValueNode>, "1": <ValueNode>, ... } }
#
# ValueNode types: constantValue, functionInvocationValue, valueReference, etc.
# We use inline nesting (no valueReference indirection) for simplicity.

#' Create an EE function invocation node
#' @noRd
.ee_call <- function(fn_name, ...) {
  args <- list(...)
  list(functionInvocationValue = list(
    functionName = fn_name,
    arguments    = args
  ))
}

#' Create an EE constant value node
#' @noRd
.ee_const <- function(value) {
  list(constantValue = value)
}

#' Wrap an expression node as a top-level Expression object
#' @noRd
.ee_expression <- function(node) {
  list(
    result = "0",
    values = list("0" = node)
  )
}

#' Convert an R Date to milliseconds since Unix epoch
#' @noRd
.date_to_ms <- function(date) {
  as.numeric(as.POSIXct(date, tz = "UTC")) * 1000
}

#' Create an EE Date node from an R Date
#' @noRd
.ee_date <- function(date) {
  .ee_call("Date", value = .ee_const(.date_to_ms(date)))
}

#' Create an EE DateRange node
#' @noRd
.ee_date_range <- function(start, end) {
  .ee_call("DateRange",
    start = .ee_date(start),
    end   = .ee_date(end)
  )
}

#' Create a date filter node
#' @noRd
.ee_date_filter <- function(start, end) {
  .ee_call("Filter.dateRangeContains",
    leftValue  = .ee_date_range(start, end),
    rightField = .ee_const("system:time_start")
  )
}

#' Load an ImageCollection
#' @noRd
.ee_load_collection <- function(collection_id) {
  .ee_call("ImageCollection.load", id = .ee_const(collection_id))
}

#' Load a single Image by ID
#' @noRd
.ee_load_image <- function(image_id) {
  .ee_call("Image.load", id = .ee_const(image_id))
}

#' Filter a collection by date
#' @noRd
.ee_filter_date <- function(collection_node, start, end) {
  .ee_call("Collection.filter",
    collection = collection_node,
    filter     = .ee_date_filter(start, end)
  )
}

#' Get the first image from a collection
#' @noRd
.ee_first <- function(collection_node) {
  .ee_call("Collection.first", collection = collection_node)
}

#' Mosaic a collection into a single image
#' @noRd
.ee_mosaic <- function(collection_node) {
  .ee_call("ImageCollection.mosaic", collection = collection_node)
}

#' Select bands from an image
#' @noRd
.ee_select <- function(image_node, bands) {
  .ee_call("Image.select",
    input         = image_node,
    bandSelectors = .ee_const(as.list(bands))
  )
}

#' Apply scale factor: image * scale_factor
#' @noRd
.ee_multiply <- function(image_node, factor) {
  if (identical(factor, 1) || identical(factor, 1L)) return(image_node)
  .ee_call("Image.multiply",
    image1 = image_node,
    image2 = .ee_call("Image.constant", value = .ee_const(factor))
  )
}

#' Apply offset: image + offset
#' @noRd
.ee_add <- function(image_node, offset) {
  if (identical(offset, 0) || identical(offset, 0L)) return(image_node)
  .ee_call("Image.add",
    image1 = image_node,
    image2 = .ee_call("Image.constant", value = .ee_const(offset))
  )
}

#' Apply scale_factor and offset: (image * scale_factor) + offset
#' @noRd
.ee_scale_offset <- function(image_node, scale_factor, offset) {
  node <- .ee_multiply(image_node, scale_factor)
  .ee_add(node, offset)
}

#' Build Image.sampleRegions expression for point extraction
#' @noRd
.ee_sample_regions <- function(image_node, points_geojson, scale) {
  .ee_call("Image.sampleRegions",
    image      = image_node,
    collection = .ee_const(points_geojson),
    scale      = .ee_const(as.integer(scale)),
    geometries = .ee_const(TRUE)
  )
}

#' Build Image.reduceRegions expression for polygon extraction
#' @noRd
.ee_reduce_regions <- function(image_node, regions_geojson, reducer, scale) {
  .ee_call("Image.reduceRegions",
    image      = image_node,
    collection = .ee_const(regions_geojson),
    reducer    = .ee_call(paste0("Reducer.", reducer)),
    scale      = .ee_const(as.integer(scale))
  )
}


#' Convert an sf/data.table of points to GeoJSON FeatureCollection
#'
#' @param coords data.table with point_id, lon, lat columns.
#' @returns A list in GeoJSON FeatureCollection format.
#' @noRd
.coords_to_geojson <- function(coords) {
  features <- lapply(seq_len(nrow(coords)), function(i) {
    list(
      type = "Feature",
      geometry = list(
        type = "Point",
        coordinates = list(coords$lon[i], coords$lat[i])
      ),
      properties = list(point_id = coords$point_id[i])
    )
  })
  list(type = "FeatureCollection", features = features)
}


# ===========================================================================
# Section 3: Grid / affine transform builders
# ===========================================================================

#' Build a grid specification from a bounding box
#'
#' @param bbox Named numeric vector with xmin, ymin, xmax, ymax.
#' @param scale Numeric. Pixel size in metres (approximate for EPSG:4326).
#' @param max_dim Integer. Maximum dimension (width or height) to prevent
#'   excessively large requests. Default 2048.
#'
#' @returns A list suitable for the `grid` field of computePixels.
#' @noRd
.build_grid <- function(bbox, scale, max_dim = 2048L) {
  # Ensure bbox is a plain numeric vector with correct names
  # (sf::st_bbox can produce double-nested names when subscripted)
  xmin <- unname(bbox[["xmin"]])
  ymin <- unname(bbox[["ymin"]])
  xmax <- unname(bbox[["xmax"]])
  ymax <- unname(bbox[["ymax"]])

  # Convert scale in metres to approximate degrees (at midpoint latitude)
  mid_lat <- (ymin + ymax) / 2
  deg_per_m <- 1 / (111320 * cos(mid_lat * pi / 180))
  pixel_size_deg <- scale * deg_per_m

  width  <- as.integer(ceiling((xmax - xmin) / pixel_size_deg))
  height <- as.integer(ceiling((ymax - ymin) / pixel_size_deg))

  # Guard against NA/NaN from degenerate inputs
  if (is.na(width) || is.na(height) || width <= 0L || height <= 0L) {
    cli::cli_abort(c(
      "Cannot compute grid dimensions for the given region and scale.",
      "i" = "Region: xmin={xmin}, ymin={ymin}, xmax={xmax}, ymax={ymax}",
      "i" = "Scale: {scale}m, pixel_size: {round(pixel_size_deg, 6)} deg"
    ))
  }

  # Clamp to max_dim
  if (width > max_dim || height > max_dim) {
    scale_ratio <- max(width, height) / max_dim
    width  <- as.integer(ceiling(width / scale_ratio))
    height <- as.integer(ceiling(height / scale_ratio))
    pixel_size_deg <- pixel_size_deg * scale_ratio
    cli::cli_warn(c(
      "!" = "Requested region exceeds {max_dim}x{max_dim} pixels at native resolution.",
      "i" = "Resampling to {width}x{height} pixels."
    ))
  }

  list(
    dimensions = list(width = width, height = height),
    affineTransform = list(
      scaleX     = pixel_size_deg,
      shearX     = 0,
      translateX = xmin,
      shearY     = 0,
      scaleY     = -pixel_size_deg,
      translateY = ymax
    ),
    crsCode = "EPSG:4326"
  )
}


# ===========================================================================
# Section 4: Low-level REST API request functions
# ===========================================================================

#' Make an authenticated REST API request
#'
#' @param endpoint Character. API endpoint path (appended to base URL).
#' @param body List. Request body (will be converted to JSON).
#' @param max_tries Integer. Max retry attempts.
#' @param initial_delay Numeric. Initial retry delay in seconds.
#' @param raw Logical. Return raw bytes instead of parsed JSON? Default FALSE.
#'
#' @returns Parsed JSON response as a list, or raw bytes if raw = TRUE.
#' @noRd
.rest_request <- function(endpoint,
                          body = NULL,
                          max_tries = 3L,
                          initial_delay = 1,
                          raw = FALSE) {
  token <- .gee_token()
  if (is.null(token)) {
    cli::cli_abort(c(
      "Not authenticated. Run {.code gee_auth()} first.",
      "i" = "See {.code gee_setup()} for first-time configuration."
    ))
  }

  # Refresh token if it's a gargle token nearing expiry
  token <- .maybe_refresh_token(token)

  project <- .gee_project()
  url <- paste0(.GEE_REST_BASE, "/projects/", project, "/", endpoint)

  # Extract access token string (handles both gargle and raw string tokens)
  access_token <- .extract_access_token(token)

  req <- httr2::request(url)
  req <- httr2::req_headers(req,
    Authorization  = paste("Bearer", access_token),
    `Content-Type` = "application/json"
  )

  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body, auto_unbox = TRUE)
  }

  req <- httr2::req_retry(req,
    max_tries = max_tries,
    backoff   = function(i) initial_delay * 2^(i - 1L)
  )

  # Don't error on HTTP status — we handle it ourselves
  req <- httr2::req_error(req, is_error = function(resp) FALSE)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_abort(c(
        "GEE REST API request failed.",
        "x" = conditionMessage(e),
        "i" = "Check your authentication with {.code gee_status()}.",
        "i" = "Endpoint: {.val {url}}"
      ))
    }
  )

  status <- httr2::resp_status(resp)
  if (status >= 400L) {
    err_body <- tryCatch(
      httr2::resp_body_json(resp),
      error = function(e) list(error = list(message = "Unknown error"))
    )
    err_msg <- err_body$error$message %||% "No error message returned."
    cli::cli_abort(c(
      "GEE REST API error (HTTP {status}).",
      "x" = err_msg,
      "i" = "Endpoint: {.val {url}}"
    ))
  }

  if (raw) {
    httr2::resp_body_raw(resp)
  } else {
    httr2::resp_body_json(resp)
  }
}


#' Request raster data via computePixels
#'
#' @param expression List. The EE expression (not wrapped in Expression).
#' @param grid List. Grid specification from .build_grid().
#' @param bands Character. Band IDs to include.
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns A terra::rast() SpatRaster.
#' @noRd
.rest_compute_pixels <- function(expression,
                                 grid,
                                 bands = NULL,
                                 max_tries = 3L,
                                 initial_delay = 1) {
  body <- list(
    expression = .ee_expression(expression),
    fileFormat = "GEO_TIFF",
    grid       = grid
  )
  if (!is.null(bands)) {
    body$bandIds <- as.list(bands)
  }

  raw_bytes <- .rest_request(
    "image:computePixels",
    body          = body,
    max_tries     = max_tries,
    initial_delay = initial_delay,
    raw           = TRUE
  )

  # Write to temp file and read with terra
  tmp <- tempfile(fileext = ".tif")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw_bytes, tmp)
  terra::rast(tmp)
}


#' Request feature data via computeFeatures
#'
#' @param expression List. The EE expression evaluating to a FeatureCollection.
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns A data.table of extracted values.
#' @noRd
.rest_compute_features <- function(expression,
                                   max_tries = 3L,
                                   initial_delay = 1) {
  body <- list(
    expression = .ee_expression(expression),
    pageSize   = 5000L
  )

  all_features <- list()
  page_token <- NULL

  repeat {
    if (!is.null(page_token)) {
      body$pageToken <- page_token
    }

    resp <- .rest_request(
      "table:computeFeatures",
      body          = body,
      max_tries     = max_tries,
      initial_delay = initial_delay
    )

    if (!is.null(resp$features)) {
      all_features <- c(all_features, resp$features)
    }

    # Check for more pages
    page_token <- resp$nextPageToken
    if (is.null(page_token) || length(page_token) == 0L) break
  }

  if (length(all_features) == 0L) {
    return(data.table::data.table())
  }

  # Parse GeoJSON features into data.table
  .parse_features_to_dt(all_features)
}


#' Parse GeoJSON features response into a data.table
#' @noRd
.parse_features_to_dt <- function(features) {
  rows <- lapply(features, function(f) {
    props <- f$properties %||% list()
    # Flatten any nested lists to single values
    props <- lapply(props, function(v) {
      if (is.null(v)) NA else v
    })
    as.data.frame(props, stringsAsFactors = FALSE)
  })
  data.table::rbindlist(rows, fill = TRUE)
}


# ===========================================================================
# Section 5: High-level extraction functions
# ===========================================================================

#' Extract raster data for a dataset via REST API
#'
#' Builds the full expression (load → filter → select → scale → offset),
#' computes the grid, and calls computePixels.
#'
#' @param meta List. Dataset metadata from .GEE_META.
#' @param date Date. Acquisition date.
#' @param region sf/sfc object or NULL (defaults to global).
#' @param bands Character or NULL (use meta$bands).
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns A terra::rast() SpatRaster.
#' @noRd
.rest_extract_raster <- function(meta,
                                 date = NULL,
                                 region = NULL,
                                 bands = NULL,
                                 max_tries = 3L,
                                 initial_delay = 1) {

  bands <- bands %||% meta$bands

  # Build expression: load → filter → first → select → scale/offset
  if (meta$temporal == "static") {
    # Static dataset: load image directly (no date filter)
    img <- .ee_load_image(meta$collection)
  } else {
    # Time-series: filter collection by date window, take first
    date_start <- date
    # Expand date window to match temporal resolution
    date_end <- switch(meta$temporal,
      daily  = date + 1L,
      "8day" = date + 8L,
      "16day" = date + 16L,
      "5day" = date + 5L,
      monthly = lubridate::ceiling_date(date, "month"),
      date + 1L
    )
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date_start, date_end)
    img <- .ee_first(col_filtered)
  }

  img <- .ee_select(img, bands)
  img <- .ee_scale_offset(img, meta$scale_factor, meta$offset)

  # Determine grid from region
  if (is.null(region)) {
    # Default: small region for safety (won't request the whole globe)
    cli::cli_abort(c(
      "{.arg region} is required for raster extraction via REST API.",
      "i" = "Provide an {.cls sf}, {.cls sfc}, or {.cls SpatExtent} object.",
      "i" = paste0("Example: {.code terra::ext(138, 140, -36, -34)}")
    ))
  }

  region <- .validate_region(region)
  bbox <- sf::st_bbox(region)
  grid <- .build_grid(bbox = bbox, scale = meta$scale)

  .rest_compute_pixels(
    expression    = img,
    grid          = grid,
    bands         = bands,
    max_tries     = max_tries,
    initial_delay = initial_delay
  )
}


#' Extract point values for a dataset via REST API
#'
#' Builds the expression (load → filter → select → scale → sampleRegions),
#' calls computeFeatures, returns data.table.
#'
#' @param meta List. Dataset metadata from .GEE_META.
#' @param date Date. Acquisition date (NULL for static datasets).
#' @param coords data.table with point_id, lon, lat columns.
#' @param bands Character or NULL (use meta$bands).
#' @param reducer Character. Spatial reducer for buffered extraction.
#' @param max_tries Integer.
#' @param initial_delay Numeric.
#'
#' @returns A data.table with point_id and extracted band values.
#' @noRd
.rest_extract_points <- function(meta,
                                 date = NULL,
                                 coords,
                                 bands = NULL,
                                 reducer = "first",
                                 max_tries = 3L,
                                 initial_delay = 1) {

  bands <- bands %||% meta$bands

  # Build expression: load → filter → first → select → scale/offset
  if (meta$temporal == "static") {
    img <- .ee_load_image(meta$collection)
  } else {
    date_start <- date
    date_end <- switch(meta$temporal,
      daily   = date + 1L,
      "8day"  = date + 8L,
      "16day" = date + 16L,
      "5day"  = date + 5L,
      monthly = lubridate::ceiling_date(date, "month"),
      date + 1L
    )
    col <- .ee_load_collection(meta$collection)
    col_filtered <- .ee_filter_date(col, date_start, date_end)
    img <- .ee_first(col_filtered)
  }

  img <- .ee_select(img, bands)
  img <- .ee_scale_offset(img, meta$scale_factor, meta$offset)

  # Build sample regions expression
  geojson <- .coords_to_geojson(coords)
  sample_expr <- .ee_sample_regions(img, geojson, meta$scale)

  .rest_compute_features(
    expression    = sample_expr,
    max_tries     = max_tries,
    initial_delay = initial_delay
  )
}
