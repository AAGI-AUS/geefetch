# expression_dataset.R -- builds the single-band image a dataset is sampled
# from. Shared by the raster route (read_gee) and the point route
# (collect_gee_data) so that date windows, spatial filtering, compositing,
# QA masks, band selection, scaling and indices are defined once.

#' Length of the acquisition window for a temporal resolution
#' @noRd
.ee_window_end <- function(date, temporal) {
  switch(
    temporal,
    daily = date + 1L,
    "5day" = date + 5L,
    "8day" = date + 8L,
    "16day" = date + 16L,
    monthly = lubridate::ceiling_date(date, "month"),
    date + 1L
  )
}

#' Bounding-box geometry node from a numeric bbox
#' @param bbox Named numeric: xmin, ymin, xmax, ymax (WGS84 degrees).
#' @noRd
.ee_bbox <- function(bbox) {
  .ee_call(
    "GeometryConstructors.BBox",
    west = .ee_const(unname(bbox[["xmin"]])),
    south = .ee_const(unname(bbox[["ymin"]])),
    east = .ee_const(unname(bbox[["xmax"]])),
    north = .ee_const(unname(bbox[["ymax"]]))
  )
}

#' MultiPoint geometry node from a table of points
#' @param coords data.table with lon, lat columns.
#' @noRd
.ee_multipoint <- function(coords) {
  pts <- lapply(seq_len(nrow(coords)), function(i) {
    list(coords$lon[i], coords$lat[i])
  })
  .ee_call("GeometryConstructors.MultiPoint", coordinates = .ee_const(pts))
}

#' Keep only the images of a collection that intersect a geometry
#' (the `filterBounds()` of the official clients)
#' @noRd
.ee_filter_bounds <- function(collection_node, geometry_node) {
  .ee_call(
    "Collection.filter",
    collection = collection_node,
    filter = .ee_call(
      "Filter.intersects",
      leftField = .ee_const(".all"),
      rightValue = .ee_call("Feature", geometry = geometry_node)
    )
  )
}

#' Rename the bands of an image
#' @noRd
.ee_rename <- function(image_node, names) {
  .ee_call(
    "Image.rename",
    input = image_node,
    names = .ee_const(as.list(names))
  )
}

#' Apply the dataset's QA mask, chosen by collection ID
#' @noRd
.ee_apply_qa <- function(image_node, collection) {
  if (grepl("^MODIS/061/MOD13", collection)) {
    .ee_mask_modis_vi(image_node)
  } else if (grepl("^MODIS/061/MOD11", collection)) {
    .ee_mask_modis_lst(image_node)
  } else if (grepl("^COPERNICUS/S2_SR", collection)) {
    .ee_mask_s2_scl(image_node)
  } else if (grepl("^LANDSAT/LC0[89]/C02/T1_L2", collection)) {
    .ee_mask_landsat_qa(image_node)
  } else {
    image_node
  }
}

#' Resolve the band(s) to sample for a dataset
#'
#' SLGA datasets derive the band from `depth` and `stat`; other datasets take
#' `variable` (WorldClim) or the registry default.
#' @noRd
.ee_dataset_bands <- function(meta, did, dots) {
  if (grepl("^slga_", did)) {
    attribute <- toupper(sub("^slga_", "", did))
    prefix <- unname(.SLGA_BAND_PREFIX[attribute])
    if (is.na(prefix)) prefix <- attribute
    depth_code <- .slga_depth_to_code(dots$depth %||% "0-5")
    stat_code <- .slga_stat_to_code(dots$stat %||% "mean")
    return(paste0(prefix, "_", depth_code, "_", stat_code))
  }
  dots$variable %||% meta$bands
}

#' Build the single-band image a dataset is sampled from
#'
#' @param meta List. Dataset metadata (built-in or user-registered).
#' @param did Character. Dataset ID (used for SLGA band construction).
#' @param date Date or NULL. Start of the acquisition window.
#' @param bounds Expression node for a geometry, or NULL. When given,
#'   time-series collections are filtered to images intersecting it before
#'   the composite is taken, so scene-based collections (Sentinel-2,
#'   Landsat) yield the scene over the request rather than an arbitrary one.
#' @param dots Named list of user arguments (`depth`, `stat`, `variable`).
#'
#' @returns List with `node` (the image expression) and `band` (the name of
#'   the band it carries, used to read values back).
#' @noRd
.ee_dataset_image <- function(
  meta,
  did,
  date = NULL,
  bounds = NULL,
  dots = list()
) {
  bands <- .ee_dataset_bands(meta, did, dots)
  index <- meta$index %||% NA_character_

  if (identical(meta$temporal, "static")) {
    img <- .ee_load_image(meta$collection)
  } else {
    col <- .ee_load_collection(meta$collection)
    col <- .ee_filter_date(col, date, .ee_window_end(date, meta$temporal))
    if (!is.null(bounds)) {
      col <- .ee_filter_bounds(col, bounds)
    }
    img <- if (identical(meta$composite, "mosaic")) {
      .ee_mosaic(col)
    } else {
      .ee_first(col)
    }
    img <- .ee_apply_qa(img, meta$collection)
  }

  if (identical(index, "ndvi")) {
    # Landsat's additive offset does not cancel in the ratio, so scale
    # and offset both bands before the difference.
    nir <- .ee_select(img, bands[1L])
    red <- .ee_select(img, bands[2L])
    nir <- .ee_scale_offset(nir, meta$scale_factor, meta$offset)
    red <- .ee_scale_offset(red, meta$scale_factor, meta$offset)
    # Fill pixels (raw 0) become negative after the offset; keep only
    # pixels where both reflectances are positive.
    zero <- .ee_call("Image.constant", value = .ee_const(0))
    valid <- .ee_call(
      "Image.and",
      image1 = .ee_call("Image.gt", image1 = nir, image2 = zero),
      image2 = .ee_call("Image.gt", image1 = red, image2 = zero)
    )
    nir <- .ee_call("Image.updateMask", image = nir, mask = valid)
    red <- .ee_call("Image.updateMask", image = red, mask = valid)
    numerator <- .ee_call("Image.subtract", image1 = nir, image2 = red)
    denominator <- .ee_call("Image.add", image1 = nir, image2 = red)
    node <- .ee_call("Image.divide", image1 = numerator, image2 = denominator)
    return(list(node = .ee_rename(node, "NDVI"), band = "NDVI"))
  }

  node <- .ee_scale_offset(.ee_select(img, bands), meta$scale_factor, meta$offset)
  list(node = node, band = bands[1L])
}
