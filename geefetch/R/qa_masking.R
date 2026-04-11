# qa_masking.R — QA masking and computed indices for satellite datasets
#
# These build EE expression nodes that apply QA masking and compute
# derived indices (e.g., NDVI) server-side.

#' Apply MODIS VI SummaryQA masking
#'
#' The MOD13A2 SummaryQA band encodes pixel quality:
#'   0 = Good, 1 = Marginal, 2 = Snow/Ice, 3 = Cloudy
#' We keep only 0 (good quality) and 1 (marginal/useful).
#'
#' @param image_node EE expression node for the full multi-band image.
#' @returns EE expression node for the masked image (QA-failed pixels = NA).
#' @noRd
.ee_mask_modis_vi <- function(image_node) {
  # Select the QA band
 qa <- .ee_select(image_node, "SummaryQA")
  # QA <= 1 means good or marginal quality
  # bitwiseAnd with 3 (mask for the 2-bit quality field), then lte 1
  mask <- .ee_call("Image.lte",
    image1 = qa,
    image2 = .ee_call("Image.constant", value = .ee_const(1L))
  )
  # Apply mask: updateMask keeps pixels where mask == 1
  .ee_call("Image.updateMask",
    image = image_node,
    mask  = mask
  )
}


#' Apply MODIS LST QC_Day masking
#'
#' The MOD11A2 QC_Day band uses bits 0-1 for mandatory QA:
#'   00 = good, 01 = other, 10 = not produced (cloud), 11 = not produced (other)
#' We keep pixels where bits 0-1 == 0 (LST produced, good quality).
#'
#' @param image_node EE expression node for the full multi-band image.
#' @returns EE expression node for the masked image.
#' @noRd
.ee_mask_modis_lst <- function(image_node) {
  qa <- .ee_select(image_node, "QC_Day")
  # bitwiseAnd(3) extracts bits 0-1; eq(0) keeps only good quality
  bits01 <- .ee_call("Image.bitwiseAnd",
    image1 = qa,
    image2 = .ee_call("Image.constant", value = .ee_const(3L))
  )
  mask <- .ee_call("Image.eq",
    image1 = bits01,
    image2 = .ee_call("Image.constant", value = .ee_const(0L))
  )
  .ee_call("Image.updateMask",
    image = image_node,
    mask  = mask
  )
}


#' Apply Sentinel-2 SCL cloud/shadow masking
#'
#' The SCL (Scene Classification Layer) band values:
#'   4 = Vegetation, 5 = Bare soils, 6 = Water, 7 = Unclassified
#' We keep 4, 5, 6, 7 (clear pixels).
#' We mask: 0 = no data, 1 = saturated, 2 = dark, 3 = cloud shadow,
#'          8 = cloud medium, 9 = cloud high, 10 = cirrus, 11 = snow
#'
#' @param image_node EE expression node for the full multi-band image.
#' @returns EE expression node for the masked image.
#' @noRd
.ee_mask_s2_scl <- function(image_node) {
  scl <- .ee_select(image_node, "SCL")
  # Keep pixels where SCL is in {4, 5, 6, 7}
  mask_4 <- .ee_call("Image.eq", image1 = scl,
                      image2 = .ee_call("Image.constant", value = .ee_const(4L)))
  mask_5 <- .ee_call("Image.eq", image1 = scl,
                      image2 = .ee_call("Image.constant", value = .ee_const(5L)))
  mask_6 <- .ee_call("Image.eq", image1 = scl,
                      image2 = .ee_call("Image.constant", value = .ee_const(6L)))
  mask_7 <- .ee_call("Image.eq", image1 = scl,
                      image2 = .ee_call("Image.constant", value = .ee_const(7L)))
  # OR them together
  mask <- .ee_call("Image.Or", image1 = mask_4, image2 = mask_5)
  mask <- .ee_call("Image.Or", image1 = mask, image2 = mask_6)
  mask <- .ee_call("Image.Or", image1 = mask, image2 = mask_7)

  .ee_call("Image.updateMask",
    image = image_node,
    mask  = mask
  )
}


#' Apply Landsat QA_PIXEL cloud/shadow masking
#'
#' QA_PIXEL uses bit flags:
#'   Bit 3 = cloud shadow, Bit 4 = cloud, Bit 5 = snow
#' We mask pixels where any of these bits are set.
#'
#' @param image_node EE expression node for the full multi-band image.
#' @returns EE expression node for the masked image.
#' @noRd
.ee_mask_landsat_qa <- function(image_node) {
  qa <- .ee_select(image_node, "QA_PIXEL")
  # Bits 3,4,5 = cloud shadow, cloud, snow -> combined mask = 56
  bits <- .ee_call("Image.bitwiseAnd",
    image1 = qa,
    image2 = .ee_call("Image.constant", value = .ee_const(56L))
  )
  # Mask where bits are zero (clear)
  mask <- .ee_call("Image.eq",
    image1 = bits,
    image2 = .ee_call("Image.constant", value = .ee_const(0L))
  )
  .ee_call("Image.updateMask",
    image = image_node,
    mask  = mask
  )
}


# ---- Computed indices ----

#' Compute Normalised Difference: (A - B) / (A + B)
#'
#' Used for NDVI, NDWI, etc. from two bands of an image.
#'
#' @param image_node EE expression node for the multi-band image.
#' @param band_a Character. NIR band name (numerator positive).
#' @param band_b Character. Red/other band name (numerator negative).
#'
#' @returns EE expression node for a single-band image with the index values.
#' @noRd
.ee_normalized_difference <- function(image_node, band_a, band_b) {
  a <- .ee_select(image_node, band_a)
  b <- .ee_select(image_node, band_b)
  numerator <- .ee_call("Image.subtract", image1 = a, image2 = b)
  denominator <- .ee_call("Image.add", image1 = a, image2 = b)
  .ee_call("Image.divide", image1 = numerator, image2 = denominator)
}
