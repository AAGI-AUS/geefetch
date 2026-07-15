# external_facts.R — provenance registry for the external facts geefetch
# asserts about Google Earth Engine (recipe 52 / Independent Oracle Principle,
# gates F13-F15).
#
# Every value geefetch hard-codes about GEE -- a collection (asset) ID, a band
# name, a scale factor, an offset, a date window, a CRS -- is a claim about an
# external authority that geefetch did not author. A test that checks such a
# value against geefetch's own `.GEE_META` (or a golden the package generated)
# proves only self-consistency. This registry makes every such fact auditable:
# it pairs each fact with the AUTHORITY that owns it and the date it was last
# diffed against that authority.
#
# Design: the fact VALUES are read live from `.GEE_META` (handler_registry.R) so
# the registry can never drift from the code it documents; this file adds only
# the PROVENANCE -- source URL, grounding date, oracle type, re-verify cadence.
# A fact is `grounded` iff its `verified_on` is a non-NA date diffed against the
# authority; otherwise it is `[unverified]` and must be treated as a hypothesis,
# not a fact (recipe 52). The independent-oracle tests live in
# `tests/testthat/test-catalogue-diff.R` (oracle B, public STAC, no GEE auth) and
# the re-grounding script in `data-raw/reverify_external_facts.R`.

# Canonical grounding tokens (recipe 52). Member code MUST hardcode these exact
# strings so a federation never drifts on the grounding label.
.GEE_GROUNDED   <- "grounded"
.GEE_UNVERIFIED <- "[unverified]"

# Oracle-type vocabulary (which independent oracle grounds a fact):
#   A = live contract (a real EE request asserts the advertised bands exist)
#   B = catalogue diff (the public GEE STAC JSON for the asset)
#   D = recorded-real property (a committed tiny real extract, value bounds)
#   E = expert sign-off (a named, dated human authority)
#   F = upstream spec/user-guide (e.g. a MODIS QA user guide)

# Build the canonical STAC catalogue URL for a GEE asset id. The public STAC is
# static JSON keyed by provider folder + the asset id with `/` -> `_`.
# (Verified 2026-06-09 against MODIS/061/MOD13A2 and COPERNICUS/S2_SR_HARMONIZED.)
.gee_stac_url <- function(collection) {
  provider <- sub("/.*$", "", collection)
  asset    <- gsub("/", "_", collection)
  sprintf(
    "https://earthengine-stac.storage.googleapis.com/catalog/%s/%s.json",
    provider, asset)
}

# Static provenance lookup, keyed by fact_id. Absent rows default to
# `[unverified]` (verified_on = NA). `reverify_by` is "stable" for asset IDs /
# band sets, "volatile" for moving date windows.
#
# GROUNDED 2026-06-09 via a live GEE STAC catalogue diff (oracle B), recorded
# here with the exact authority diffed:
#   - modis_ndvi.collection : STAC entry resolves (HTTP 200).
#   - modis_ndvi.scale_factor: STAC eo:bands["NDVI"]$`gee:scale` == 0.0001.
#   - sentinel2.collection  : STAC entry resolves (HTTP 200).
#   - sentinel2.scale_factor: STAC eo:bands["B8"|"B4"]$`gee:scale` == 0.0001.
#   - sentinel2.offset      : no band `gee:offset` in STAC (== 0); the
#       S2_SR_HARMONIZED product already corrects the post-2022 -1000 DN shift
#       upstream, so a package-level offset of 0 is consistent. (The declared
#       scale/offset are not applied on the S2 NDVI path anyway -- handlers.R
#       computes NDVI from raw DN via .ee_normalized_difference; scale cancels
#       in the ratio. Dead-but-consistent metadata, not a value error.)
# Everything else is [unverified] until test-catalogue-diff.R / a live run
# grounds it.
.GEE_FACT_PROVENANCE <- list(
  "modis_ndvi.collection"     = list(verified_on = "2026-06-09",
                                     oracle_types = c("A", "B"),
                                     reverify_by  = "stable"),
  "modis_ndvi.scale_factor"   = list(verified_on = "2026-06-09",
                                     oracle_types = c("B", "D"),
                                     reverify_by  = "stable"),
  "sentinel2_ndvi.collection" = list(verified_on = "2026-06-09",
                                     oracle_types = c("A", "B"),
                                     reverify_by  = "stable"),
  "sentinel2_ndvi.scale_factor" = list(verified_on = "2026-06-09",
                                     oracle_types = c("B", "D"),
                                     reverify_by  = "stable"),
  "sentinel2_ndvi.offset"     = list(verified_on = "2026-06-09",
                                     oracle_types = c("B", "D", "F"),
                                     reverify_by  = "stable"),
  # GROUNDED 2026-06-09 by CORRECTING a confirmed wrong fact the catalogue-diff
  # oracle caught (the self-consistency tests passed both):
  #   - slga_phc.bands : declared `PHC_000_005_EV`; the authority advertises
  #       `pHc_000_005_EV` (GEE band names are case-sensitive). Fixed in
  #       handler_registry.R (.SLGA_BAND_PREFIX) + handlers.R.
  #   - worldclim_bio.collection : declared `WORLDCLIM/V2/BIO`, which 404s in the
  #       GEE STAC; the hosted asset is `WORLDCLIM/V1/BIO`. Fixed in
  #       handler_registry.R.
  "slga_phc.bands"            = list(verified_on = "2026-06-09",
                                     oracle_types = c("B"),
                                     reverify_by  = "stable"),
  "worldclim_bio.collection"  = list(verified_on = "2026-06-09",
                                     oracle_types = c("A", "B"),
                                     reverify_by  = "stable")
)

#' External-fact provenance registry
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Enumerates every fact `geefetch` asserts about Google Earth Engine -- each
#' dataset's collection (asset) ID, scale factor, offset, band set, and start
#' date -- alongside the external authority that owns the fact and the date the
#' fact was last diffed against that authority. A fact whose `verified_on` is
#' `NA` is reported as `[unverified]`: a value the package asserts but has **not**
#' grounded against an independent oracle, and which must be treated as a
#' hypothesis rather than a fact.
#'
#' The fact values are read live from the internal registry, so this table can
#' never drift from the code it documents. Grounding is established by the
#' independent-oracle tests (catalogue diff against the public GEE STAC, and an
#' optional live-contract check); see the package tests.
#'
#' @param grounded_only Logical. If `TRUE`, return only facts with a non-`NA`
#'   `verified_on`. Default `FALSE` (return all, including `[unverified]`).
#'
#' @returns A [data.table::data.table], one row per externally-grounded fact,
#' with columns:
#' \describe{
#'   \item{dataset}{Normalised dataset ID.}
#'   \item{fact_id}{`<dataset>.<fact>` identifier.}
#'   \item{kind}{Fact kind: `locator`, `enum`, `scale`, or `bound`.}
#'   \item{value}{The value the package asserts (read live from the registry).}
#'   \item{source}{The authority that owns the fact (a GEE STAC catalogue URL).}
#'   \item{verified_on}{ISO date last diffed against `source`, or `NA`.}
#'   \item{grounding}{`"grounded"` or `"[unverified]"`.}
#'   \item{oracle_types}{Which oracle(s) ground (or would ground) the fact.}
#'   \item{reverify_by}{`"stable"` or `"volatile"`.}
#' }
#'
#' @family utilities
#' @seealso [gee_datasets()]
#'
#' @examplesIf interactive()
#' gee_external_facts()
#' gee_external_facts(grounded_only = TRUE)
#'
#' @export
gee_external_facts <- function(grounded_only = FALSE) {
  meta <- .gee_combined_meta()

  # The load-bearing fact families per dataset (recipe 52 silent classes 3 & 4
  # first: scale/offset corrupt values silently; date windows gate input).
  rows <- lapply(names(meta), function(nm) {
    m <- meta[[nm]]
    facts <- list(
      list(fact = "collection",   kind = "locator",
           value = m$collection),
      list(fact = "bands",        kind = "enum",
           value = paste(m$bands, collapse = ", ")),
      list(fact = "scale_factor", kind = "scale",
           value = format(m$scale_factor, scientific = FALSE)),
      list(fact = "offset",       kind = "scale",
           value = format(m$offset, scientific = FALSE)),
      list(fact = "date_start",   kind = "bound",
           value = m$date_start %||% NA_character_)
    )
    data.table::rbindlist(lapply(facts, function(f) {
      fid  <- paste0(nm, ".", f$fact)
      prov <- .GEE_FACT_PROVENANCE[[fid]]
      von  <- if (is.null(prov)) NA_character_ else prov$verified_on
      data.table::data.table(
        dataset      = nm,
        fact_id      = fid,
        kind         = f$kind,
        value        = as.character(f$value),
        source       = .gee_stac_url(m$collection),
        verified_on  = von,
        grounding    = if (is.na(von)) .GEE_UNVERIFIED else .GEE_GROUNDED,
        oracle_types = if (is.null(prov)) NA_character_
                       else paste(prov$oracle_types, collapse = ","),
        reverify_by  = if (is.null(prov)) NA_character_ else prov$reverify_by
      )
    }))
  })

  dt <- data.table::rbindlist(rows)
  if (isTRUE(grounded_only)) dt <- dt[!is.na(verified_on)]
  dt[]
}
