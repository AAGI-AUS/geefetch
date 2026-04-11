# geefetch: Executive Summary

**Google Earth Engine Fast Easy Terrestrial Covariate Harvester**

**Date:** 2026-04-11
**Authors:** Max Moldovan and Adam Sparks
**Status:** Proposal — awaiting review

---

## The Problem

Researchers in ecology, agriculture, and environmental science need spatio-temporal covariate data from Google Earth Engine (GEE) — the world's richest free archive of satellite imagery and climate data. The current R pathway is painful:

1. **Python dependency wall.** `rgee` requires reticulate, a working Python environment, and the `earthengine-api` pip package. Over 50% of `rgee` GitHub issues concern `ee_Initialize()` failures — authentication, Python discovery, and credential expiry.
2. **No unified extraction interface.** Each GEE collection has different bands, scales, QA masking, and temporal resolution. Users write repetitive, brittle extraction code.
3. **No caching.** Repeated GEE calls for the same data are common. Each round-trip is slow (~2–10s per extraction) and counts against quotas.
4. **R is 5–10x behind Python.** Python's `geemap` (3,900+ stars), `eemont`, and Google's official `Xee` (xarray backend) offer dramatically superior workflows. R has no equivalent.

**The gap is real and large.** No existing R package provides a clean, high-level, multi-dataset GEE extraction interface with caching and batch support — let alone one that works without Python.

---

## The Solution

**geefetch** provides a unified, ergonomic R interface for extracting environmental covariates from Google Earth Engine, modelled on the proven architecture of the `nert` package.

### Architecture (following `nert`)

| Component | nert equivalent | Purpose |
|---|---|---|
| `read_gee()` | `read_tern()` | Central dispatcher — one function, any dataset |
| `read_modis_ndvi()`, `read_era5()`, ... | `read_smips()`, `read_slga()` | Convenience aliases with named, documented parameters |
| Internal handlers | `.read_tern_smips()`, etc. | Encapsulated per-dataset logic (bands, QA, scaling) |
| Dataset registry | `.TERN_ALIASES` + `switch()` | Static alias table + dispatcher |
| `collect_gee_data()` | `collect_tern_data()` | Batch extraction → `data.table` |
| `gee_status()` / `gee_setup()` | `get_key()` | Authentication & dependency management |

### Dual Backend — The Strategic Differentiator

The single most important architectural decision:

| Backend | Mechanism | When used |
|---|---|---|
| **REST API (primary)** | Direct HTTP via `httr2` + `gargle` auth | Default. No Python. No reticulate. |
| **rgee (fallback)** | Full EE Python API via reticulate | Complex server-side computations, advanced users |

The GEE REST API v1 endpoints (`computePixels`, `computeFeatures`, high-volume endpoint) are production-stable and support the core operations researchers need: point/polygon extraction, time series, and raster downloads. By defaulting to REST, **geefetch installs and works like any normal R package** — `install.packages("geefetch")` and go.

This eliminates the #1 adoption barrier in the entire GEE-in-R ecosystem.

### User Experience

```r
# Install — no Python, no conda, no reticulate
install.packages("geefetch")

# Authenticate — familiar gargle flow (like googlesheets4, googledrive)
gee_auth()

# One-line extraction → SpatRaster
ndvi <- read_modis_ndvi(date = "2024-06-15")

# Point extraction with batch → data.table
covariates <- collect_gee_data(
  xy    = my_sites,          # sf or data.frame with lon/lat
  dates = c("2024-01-01", "2024-12-31"),
  datasets = c("modis_ndvi", "era5_temp", "chirps_precip", "srtm_elevation")
)
```

---

## Competitive Landscape

| Package | Stars | Python needed? | Caching | Batch extract | Multi-dataset | Maintained? |
|---|---|---|---|---|---|---|
| **rgee** | 774 | Yes | No | Manual | Manual | Sporadic |
| **rgeeExtra** | ~100 | Yes | No | No | No | Dead (2023) |
| **tidyrgee** | ~60 | Yes | No | Partial | No | Minimal |
| **rgeedim** | ~40 | Yes | No | No | No | Active |
| **geefetch** (proposed) | — | **No** | **Yes** | **Yes** | **Yes** | — |

**geefetch would be the only R package that accesses GEE without Python.** This alone is a category-defining advantage.

---

## Strategic Value

- **Fills the largest gap in the R-GEE ecosystem:** Python-free, high-level, multi-dataset extraction with caching.
- **Target audience:** Environmental modellers, ecologists, precision agriculture researchers, climate analysts — anyone who needs GEE data in R but doesn't want to manage Python.
- **Lower barrier extends the audience:** Students, government analysts, and applied researchers who would never successfully configure `rgee` can use geefetch immediately.
- **Architecture scales:** New GEE datasets are added by writing a handler function and registering an alias — no changes to core code. Community contributions follow the same pattern.
- **Companion to nert:** Same architecture, same output conventions (`terra::rast()`, `data.table`), same documentation standard. Users of one package are immediately fluent in the other.

---

## Honest Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| REST API coverage gaps (some EE operations need server-side computation) | High | Medium | Dual backend: fall back to rgee for advanced operations; document which datasets/operations require rgee |
| REST API rate limits / quota changes | Medium | Medium | Aggressive caching; exponential backoff; batch chunking |
| gargle auth complexity (service accounts, OAuth consent screens) | Medium | High | `gee_setup()` wizard; precompiled vignette with screenshots (nert pattern) |
| GEE REST API deprecation or breaking changes | High | Low | Version-pin endpoints; abstract behind internal handler layer |
| CRAN compliance (rgee in Suggests, conditional tests) | Medium | Low | REST-first means core functionality needs zero Suggests; `skip_on_cran()` for GEE tests |
| Scope creep beyond extraction | Medium | Medium | Strict scope: extraction + caching only. No modelling, no mapping, no compositing |
| Maintenance burden as dataset count grows | Low | High | Modular handlers; community contribution template; CI per-handler tests |

### What Could Kill This Project

Be honest:
- **If Google restricts the REST API** to paid tiers or deprecates v1 endpoints, the Python-free advantage disappears. Mitigation: the rgee backend remains functional.
- **If `rgee` dies completely** and no REST fallback exists for advanced operations, some features become impossible. Mitigation: REST API coverage is expanding, not shrinking.
- **If we over-scope** (mapping, modelling, compositing), development stalls. Mitigation: ruthless scope discipline — extraction only.

---

## Expected Outcomes

1. **v0.1.0 release** on GitHub within 10–14 weeks of active development.
2. **Python-free GEE access** — a first for any R package.
3. **Comprehensive documentation:** pkgdown site, 3+ precompiled vignettes, full roxygen2 reference.
4. **CRAN submission** feasible (REST-first design avoids reticulate complications).
5. **Companion paper** for JOSS or Methods in Ecology and Evolution.
6. **Community traction** via rOpenSci review pipeline.

---

## Changes from v1 of This Document

| What changed | Why |
|---|---|
| **Added REST API as primary backend** | Research revealed GEE REST API v1 is production-stable for extraction workflows. Eliminates the #1 adoption barrier (Python). No existing R package does this. |
| **Renamed functions to follow nert convention** | `gf_extract()` → `read_gee()`, `gf_collect()` → `collect_gee_data()`, `gf_ndvi()` → `read_modis_ndvi()`. Matches nert's `read_*` / `collect_*` pattern for cross-package consistency. |
| **Added competitive landscape table** | v1 assumed no competition. Reality: 4+ packages exist but all require Python and none offer batch multi-dataset extraction. geefetch's positioning is clearer with this context. |
| **Sharpened risk assessment** | v1 risks were generic. Now includes honest "what could kill this" section and rates likelihood alongside severity. |
| **Removed "post-release roadmap" from exec summary** | Belongs in implementation plan, not executive summary. Exec summary should sell the vision and be honest about risks, not speculate about future features. |
| **Dropped `fst` caching from exec summary** | Implementation detail. Exec summary mentions caching exists; the plan specifies the mechanism. |
| **Output format aligned with nert** | v1 said "returns data.table everywhere". Corrected: spatial reads return `terra::rast()`, batch extraction returns `data.table` — exactly matching nert. |
