# reexports.R — Re-exported functions from terra and sf
#
# These are the functions users need immediately after loading geefetch.
# Re-exporting avoids the need for library(terra) or library(sf) in
# simple workflows.

#' @importFrom terra ext rast plot
#' @export
terra::ext

#' @export
terra::rast

#' @importFrom sf st_as_sf st_bbox st_as_sfc
#' @export
sf::st_as_sf

#' @export
sf::st_bbox
