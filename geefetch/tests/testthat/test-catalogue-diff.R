# test-catalogue-diff.R — independent-oracle tests (recipe 52 gate F14).
#
# This is the oracle the registry's self-consistency tests are NOT. It diffs the
# facts geefetch asserts about GEE (in `.GEE_META`) against the AUTHORITY that
# owns them: the public Google Earth Engine STAC catalogue (static JSON, no GEE
# auth or project needed). The "expected" side of every assertion is the live
# STAC value; the "actual" side is geefetch's hard-coded value. A failure here
# is a finding about the package, not a bug in the test.
#
# Why this matters: `test-handler_registry.R` only checks the registry against
# itself (fields present, aliases resolve), so a fabricated collection ID or a
# wrong scale factor stays green. This file is what would have caught the nert
# class of error.
#
# Network-gated. The suite declares NO_INTERNET=true by default (setup.R), so
# these opt in explicitly: set GEEFETCH_ORACLE=1 to run. Also skip on CRAN.

skip_on_cran()
skip_if(Sys.getenv("GEEFETCH_ORACLE") != "1",
        "set GEEFETCH_ORACLE=1 to run the live STAC catalogue-diff oracle")
skip_if_not_installed("httr2")

# Fetch + parse one asset's STAC JSON. Returns NULL on a non-200 (a NULL is
# itself the finding for a fabricated/renamed collection ID).
.fetch_stac <- function(collection) {
  url <- .gee_stac_url(collection)
  req <- httr2::req_error(httr2::request(url), is_error = function(r) FALSE)
  resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
  if (is.null(resp) || httr2::resp_status(resp) != 200L) return(NULL)
  # The STAC bucket serves JSON as text/plain, so bypass the content-type check.
  httr2::resp_body_json(resp, check_type = FALSE)
}

# Index a STAC document's eo:bands by name -> band object.
.stac_bands <- function(stac) {
  bands <- stac$summaries$`eo:bands`
  if (is.null(bands)) return(list())
  stats::setNames(bands, vapply(bands, function(b) b$name %||% NA_character_,
                                character(1)))
}

meta <- .GEE_META

test_that("every declared collection ID resolves in the GEE STAC", {
  # A 404 here = a fabricated or renamed asset ID (recipe 52 class 1/2).
  for (nm in names(meta)) {
    stac <- .fetch_stac(meta[[nm]]$collection)
    expect_false(is.null(stac),
                 label = sprintf("STAC resolves for %s (%s)",
                                 nm, meta[[nm]]$collection))
    if (!is.null(stac)) {
      expect_identical(stac$id, meta[[nm]]$collection,
                       label = sprintf("STAC id matches for %s", nm))
    }
  }
})

test_that("every declared band exists in the asset's STAC band list", {
  # A band absent from the authority's list = a fabricated band name.
  for (nm in names(meta)) {
    stac <- .fetch_stac(meta[[nm]]$collection)
    skip_if(is.null(stac), sprintf("STAC unavailable for %s", nm))
    stac_band_names <- names(.stac_bands(stac))
    for (b in meta[[nm]]$bands) {
      # qa_band aside, the value bands must be advertised by the authority.
      expect_true(b %in% stac_band_names,
                  label = sprintf("band '%s' advertised for %s (%s)",
                                  b, nm, meta[[nm]]$collection))
    }
  }
})

test_that("the decode scale_factor matches the STAC band scale", {
  # Correspondence is asserted ONLY where geefetch's `scale_factor` is meant to
  # BE the STAC band decode scale (raw DN -> physical value). It is deliberately
  # NOT asserted where `scale_factor` is a unit conversion geefetch performs
  # itself (era5_precip m->mm = 1000; era5_temp K->C via offset; chirps/srtm/
  # slga = 1): those have no counterpart in the STAC band `gee:scale` and a diff
  # would be a false failure. Each pair below names the value band to compare.
  decode_pairs <- list(
    modis_ndvi     = "NDVI",
    modis_lst      = "LST_Day_1km",
    sentinel2_ndvi = "B8",
    landsat_ndvi   = "SR_B5",
    worldclim_bio  = "bio01",
    openlandmap_soc  = "b0",
    openlandmap_clay = "b0",
    openlandmap_ph   = "b0"
  )
  for (nm in names(decode_pairs)) {
    skip_if(is.null(meta[[nm]]), sprintf("%s not in registry", nm))
    stac <- .fetch_stac(meta[[nm]]$collection)
    skip_if(is.null(stac), sprintf("STAC unavailable for %s", nm))
    band <- .stac_bands(stac)[[decode_pairs[[nm]]]]
    skip_if(is.null(band) || is.null(band$`gee:scale`),
            sprintf("STAC declares no gee:scale for %s/%s",
                    nm, decode_pairs[[nm]]))
    # Authority on the left, package's claim on the right.
    expect_equal(band$`gee:scale`, meta[[nm]]$scale_factor,
                 tolerance = 1e-12,
                 label = sprintf(
                   "scale_factor for %s (%s) matches STAC gee:scale",
                   nm, decode_pairs[[nm]]
                 ))
    # Offset, where the STAC band declares one (Landsat SR carries gee:offset).
    if (!is.null(band$`gee:offset`)) {
      expect_equal(band$`gee:offset`, meta[[nm]]$offset, tolerance = 1e-12,
                   label = sprintf("offset for %s matches STAC gee:offset", nm))
    }
  }
})
