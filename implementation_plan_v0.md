# geefetch: Implementation Plan

**Google Earth Engine Fast Easy Terrestrial Covariate Harvester**

**Date:** 2026-04-11
**Authors:** Max Moldovan and Adam Sparks

---

## 1. Objective

Build a production-quality R package that provides a unified, ergonomic interface for extracting spatio-temporal environmental covariates from Google Earth Engine.

**Success criteria:**

- `R CMD check --as-cran` passes with zero errors/warnings/notes
- Installs cleanly without Python when GEE features are not used
- Extracts data from ≥10 major GEE datasets via a single dispatcher + convenience aliases
- Batch extraction across N locations × M dates × K datasets returns a tidy `data.table`
- Smart caching eliminates redundant GEE calls
- Comprehensive documentation: ≥2 vignettes, full pkgdown site, all exports documented with examples
- Companion paper draft ready for submission

---

## 2. Architecture & Design

### 2.1 Core Design Pattern: Handler Registry + Dispatcher

```
User-facing API
├── gf_extract(dataset, points, dates, ...)
├── gf_ndvi(points, dates, ...)
├── gf_era5_temp(points, dates, ...)
├── gf_slga(points, dates, variable, ...)
├── gf_smips(points, dates, ...)
├── gf_collect(points, dates, datasets, ...)
└── gf_setup() / gf_status()

Internal layer
├── handler registry (list of dataset handler functions)
├── individual handlers (one per dataset/collection)
├── GEE connection manager (wraps rgee::ee_Initialize)
├── cache manager
└── validation & error utilities
```

### 2.2 Handler Registry

Each supported GEE dataset is registered as a named handler — a list containing:

| Field | Description |
|---|---|
| `collection` | GEE ImageCollection ID (e.g., `"MODIS/061/MOD13A2"`) |
| `bands` | Character vector of bands to extract |
| `scale` | Native resolution in metres |
| `temporal_resolution` | `"daily"`, `"8day"`, `"16day"`, `"monthly"`, `"static"` |
| `qa_mask_fn` | Optional function for QA/cloud masking |
| `post_process_fn` | Optional function for unit conversion, scaling factors |
| `description` | Human-readable dataset description |
| `citation` | Preferred citation string |

New datasets are added by writing a handler and registering it — no changes to core code.

```r
# Internal: registering a handler
.gf_registry <- new.env(parent = emptyenv())

register_handler <- function(name, handler) {
  .gf_registry[[name]] <- handler
}

# Example handler
register_handler("modis_ndvi", list(
  collection         = "MODIS/061/MOD13A2",
  bands              = "NDVI",
  scale              = 1000,
  temporal_resolution = "16day",
  qa_mask_fn         = .mask_modis_vi_quality,
  post_process_fn    = function(x) x * 0.0001,
  description        = "MODIS Terra Vegetation Indices 16-Day L3 1km",
  citation           = "Didan, K. (2021). MODIS/Terra Vegetation Indices..."
))
```

### 2.3 Dispatcher: `gf_extract()`

```r
gf_extract <- function(dataset,
                       points,
                       dates = NULL,
                       buffer = 0,
                       reducer = "mean",
                       cache = TRUE,
                       ...) {
  # 1. Validate inputs
  # 2. Look up handler from registry
  # 3. Check rgee availability (informative error if missing)
  # 4. Check cache
  # 5. Build & execute GEE extraction via handler
  # 6. Post-process (QA masking, unit conversion)
  # 7. Cache result
  # 8. Return data.table
}
```

### 2.4 Batch Extraction: `gf_collect()`

```r
gf_collect <- function(points,
                       dates,
                       datasets,
                       buffer = 0,
                       reducer = "mean",
                       cache = TRUE,
                       parallel = FALSE,
                       ...) {
  # 1. Validate all datasets exist in registry
  # 2. Loop/apply over datasets, calling gf_extract() for each
  # 3. Merge results into single wide data.table (one row per point-date)
  # 4. Return merged data.table with metadata attributes
}
```

### 2.5 Convenience Aliases

Auto-generated thin wrappers:

```r
gf_ndvi <- function(points, dates, ...) {
  gf_extract("modis_ndvi", points = points, dates = dates, ...)
}
```

A factory function generates these to avoid boilerplate:

```r
.make_alias <- function(dataset_name) {
  force(dataset_name)
  function(points, dates, ...) {
    gf_extract(dataset_name, points = points, dates = dates, ...)
  }
}
```

### 2.6 Dependency Strategy

```
Imports:
  data.table, sf, methods

Suggests:
  rgee, reticulate, envfetch,
  testthat, knitr, rmarkdown, ggplot2, viridis
```

- **All GEE calls are guarded** by `requireNamespace("rgee", quietly = TRUE)`.
- Informative error messages guide users through setup if `rgee` is missing.
- `gf_setup()` provides a guided, interactive setup wizard.
- `gf_status()` reports: rgee installed? Python found? ee authenticated? Cache dir writable?

### 2.7 Caching Strategy

| Layer | Mechanism |
|---|---|
| In-memory | `data.table` keyed by `(dataset, point_id, date_range, buffer, reducer)` |
| On-disk | Hashed `.fst` files in `rappdirs::user_cache_dir("geefetch")` |
| Cache key | SHA256 of `(collection_id, point_wkt, date_start, date_end, buffer, reducer, bands)` |
| Invalidation | TTL-based (configurable, default 30 days for dynamic datasets, infinite for static) |
| Control | `cache = TRUE/FALSE` argument; `gf_clear_cache()` utility |

---

## 3. Technical Stack & Tools

| Component | Tool |
|---|---|
| Core language | R (≥ 4.1.0) |
| Tabular data | `data.table` |
| Spatial | `sf` |
| GEE interface | `rgee` (Suggests) |
| Caching | `fst` for disk, internal env for memory |
| Testing | `testthat` (edition 3) |
| Documentation | `roxygen2`, `pkgdown`, `knitr`/`rmarkdown` vignettes |
| CI | GitHub Actions (R-CMD-check, test coverage, pkgdown deploy) |
| Style | `lintr`, `styler` (tidyverse style with snake_case) |

---

## 4. Supported Datasets (Initial Release)

### Tier 1 — Launch (Phase 2)

| Alias | GEE Collection | Domain | Resolution |
|---|---|---|---|
| `modis_ndvi` | MODIS/061/MOD13A2 | Vegetation | 1 km / 16-day |
| `modis_lst` | MODIS/061/MOD11A2 | Temperature | 1 km / 8-day |
| `era5_temp` | ECMWF/ERA5_LAND/DAILY | Climate | 11 km / daily |
| `era5_precip` | ECMWF/ERA5_LAND/DAILY | Climate | 11 km / daily |
| `srtm_elevation` | USGS/SRTMGL1_003 | Topography | 30 m / static |
| `chirps_precip` | UCSB-CHG/CHIRPS/DAILY | Precipitation | 5.5 km / daily |

### Tier 2 — Extended (Phase 4)

| Alias | GEE Collection | Domain | Resolution |
|---|---|---|---|
| `slga_clay` | CSIRO/SLGA | Soil (AU) | 90 m / static |
| `slga_ph` | CSIRO/SLGA | Soil (AU) | 90 m / static |
| `smips_moisture` | CSIRO/SMIPS | Soil moisture (AU) | ~5 km / daily |
| `sentinel2_ndvi` | COPERNICUS/S2_SR_HARMONIZED | Vegetation | 10 m / 5-day |
| `landsat_ndvi` | LANDSAT/LC09/C02/T1_L2 | Vegetation | 30 m / 16-day |
| `worldclim_bio` | WorldClim V2 | Bioclimatic | 1 km / static |

### Tier 3 — Community-contributed (Post-release)

Open handler registry for user-defined datasets via `gf_register()`.

---

## 5. Step-by-Step Breakdown

### Phase 1: Package Skeleton & Infrastructure (Week 1–2)

| Step | Task | Complexity |
|---|---|---|
| 1.1 | Initialise package structure (`usethis::create_package()`) | Low |
| 1.2 | Set up DESCRIPTION, NAMESPACE, LICENSE (MIT), .Rbuildignore | Low |
| 1.3 | Implement handler registry (internal environment + register/lookup functions) | Low |
| 1.4 | Implement input validation utilities (`validate_points()`, `validate_dates()`, `validate_dataset()`) | Low |
| 1.5 | Implement `gf_status()` — dependency and authentication check | Low |
| 1.6 | Implement `gf_setup()` — guided setup wizard (check rgee, Python, ee auth) | Medium |
| 1.7 | Set up GitHub repo, GitHub Actions CI (R-CMD-check matrix: macOS, Ubuntu, Windows) | Low |
| 1.8 | Set up `testthat` edition 3, code coverage reporting | Low |

**Deliverable:** Installable package skeleton that passes `R CMD check`, CI green.

### Phase 2: Core Extraction Engine (Week 3–5)

| Step | Task | Complexity |
|---|---|---|
| 2.1 | Implement GEE connection manager (wraps `rgee::ee_Initialize()`, handles auth gracefully) | Medium |
| 2.2 | Implement `gf_extract()` dispatcher — full pipeline: validate → lookup → connect → extract → post-process → return | High |
| 2.3 | Implement Tier 1 dataset handlers (6 handlers: MODIS NDVI, MODIS LST, ERA5 temp, ERA5 precip, SRTM, CHIRPS) | Medium |
| 2.4 | Implement QA masking functions for MODIS collections | Medium |
| 2.5 | Implement temporal aggregation logic (daily → monthly, custom windows) | Medium |
| 2.6 | Implement spatial buffer extraction with configurable reducers (mean, median, min, max, sd) | Medium |
| 2.7 | Generate convenience aliases via factory function for all Tier 1 datasets | Low |
| 2.8 | Unit tests for dispatcher, each handler, edge cases (empty results, invalid coords, date out of range) | Medium |

**Deliverable:** Working extraction for 6 datasets. Core API functional.

### Phase 3: Caching & Batch Extraction (Week 5–6)

| Step | Task | Complexity |
|---|---|---|
| 3.1 | Implement cache key hashing (SHA256 of extraction parameters) | Low |
| 3.2 | Implement on-disk cache (`.fst` files in user cache dir) | Medium |
| 3.3 | Implement in-memory cache (session-level, keyed environment) | Low |
| 3.4 | Implement cache TTL and `gf_clear_cache()` | Low |
| 3.5 | Implement `gf_collect()` — batch multi-dataset extraction returning wide `data.table` | Medium |
| 3.6 | Add progress reporting for batch operations (`cli` package) | Low |
| 3.7 | Tests for caching (hit/miss, invalidation, concurrent access) | Medium |

**Deliverable:** Full caching pipeline. Batch extraction functional.

### Phase 4: Extended Datasets & Polish (Week 7–8)

| Step | Task | Complexity |
|---|---|---|
| 4.1 | Implement Tier 2 handlers (SLGA, SMIPS, Sentinel-2, Landsat, WorldClim) | Medium |
| 4.2 | Implement `gf_register()` for user-defined custom dataset handlers | Medium |
| 4.3 | Implement `gf_datasets()` — list all available datasets with metadata | Low |
| 4.4 | Implement `print`/`summary` methods for geefetch results | Low |
| 4.5 | Edge case hardening: network failures, GEE quotas, malformed geometries, CRS handling | Medium |
| 4.6 | Performance profiling and optimisation of extraction pipeline | Medium |

**Deliverable:** 12+ datasets supported. User-extensible registry. Robust error handling.

### Phase 5: Documentation & Vignettes (Week 8–10)

| Step | Task | Complexity |
|---|---|---|
| 5.1 | Full roxygen2 documentation for all exported functions (descriptions, params, return, examples) | Medium |
| 5.2 | Vignette 1: "Getting Started with geefetch" — installation, setup, first extraction | Medium |
| 5.3 | Vignette 2: "Batch Environmental Covariate Extraction for Ecological Models" — real-world workflow | Medium |
| 5.4 | Vignette 3: "Adding Custom GEE Datasets" — handler authoring guide | Low |
| 5.5 | Build and deploy pkgdown site (GitHub Pages) | Low |
| 5.6 | Write README.md with badges, quick-start, and feature overview | Low |
| 5.7 | NEWS.md, CITATION file, ORCID metadata | Low |

**Deliverable:** Publication-quality documentation. pkgdown site live.

### Phase 6: Testing, Review & Release (Week 10–12)

| Step | Task | Complexity |
|---|---|---|
| 6.1 | Comprehensive test suite: ≥80% code coverage target | Medium |
| 6.2 | Mock-based tests for GEE calls (test without live GEE connection) | Medium |
| 6.3 | Integration tests with live GEE (skipped on CRAN, run in CI with credentials) | Medium |
| 6.4 | `R CMD check --as-cran` on all platforms — zero issues | Medium |
| 6.5 | `goodpractice::gp()` audit and remediation | Low |
| 6.6 | Peer review (internal or rOpenSci pre-submission) | Low |
| 6.7 | GitHub release v0.1.0 | Low |
| 6.8 | CRAN submission (if appropriate) or rOpenSci review | Medium |
| 6.9 | JOSS paper draft | Medium |

**Deliverable:** Released, tested, documented package. Paper draft.

---

## 6. Key Decisions & Trade-offs

### Decision 1: `rgee` in Suggests vs Imports

| Option | Pros | Cons |
|---|---|---|
| **Suggests (chosen)** | Clean install, CRAN-friendly, broader audience | Slightly more complex internal code (guards everywhere) |
| Imports | Simpler code | Breaks install for non-GEE users, likely CRAN rejection |

**Rationale:** CRAN eligibility and install friction trump code simplicity. The guard pattern is a one-time cost.

### Decision 2: `data.table` vs tibble for output

| Option | Pros | Cons |
|---|---|---|
| **data.table (chosen)** | Fast, memory-efficient, reference semantics ideal for large extractions | Less familiar to tidyverse-only users |
| tibble | Familiar to tidyverse users | Slower for large data, adds dependency |

**Rationale:** Performance matters for batch extractions over large point sets. Users can convert via `as_tibble()` trivially.

### Decision 3: On-disk cache format

| Option | Pros | Cons |
|---|---|---|
| **fst (chosen)** | Extremely fast read/write, compression, data.table-native | Extra dependency |
| RDS | No extra dependency | Slow for large data |
| Arrow/Parquet | Cross-language, columnar | Heavier dependency |

**Rationale:** `fst` is the fastest option for R tabular data and integrates seamlessly with `data.table`.

### Decision 4: Naming convention — `gf_` prefix

All exported functions use the `gf_` prefix (short for geefetch). This:
- Avoids namespace collisions
- Enables autocomplete discovery
- Follows established R conventions (`st_` in sf, `ee_` in rgee)

---

## 7. Potential Risks & Edge Cases

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| rgee breaking changes | Medium | High | Pin minimum version, integration tests, monitor rgee releases |
| GEE authentication changes | Low | High | Abstract auth behind `gf_setup()`; document multiple auth methods |
| GEE quota exhaustion | Medium | Medium | Caching reduces calls; batch mode with rate limiting; informative errors |
| Coordinate system mismatches | Medium | Low | Force WGS84 internally; auto-transform with warning |
| Empty/NA results for ocean or missing data | High | Low | Graceful handling: return NA with informative attributes |
| Large extraction requests timing out | Medium | Medium | Chunking strategy for >1000 points; progress bar; retry logic |
| Python environment conflicts | Medium | High | Document isolated conda env; `gf_setup()` creates dedicated env |
| Cached data becoming stale | Low | Low | TTL-based invalidation; `gf_clear_cache()` |

---

## 8. Documentation & Output Plan

### Package Documentation

- **Function reference:** Full roxygen2 Rd pages for every export, with runnable examples using bundled or standard datasets
- **Vignettes:** 3 vignettes covering setup, workflows, and extensibility
- **pkgdown site:** Deployed via GitHub Actions to GitHub Pages

### Academic Output

- **Target journal:** JOSS (Journal of Open Source Software) — natural fit for R packages
- **Alternative venues:** Methods in Ecology and Evolution (application note), Environmental Modelling & Software
- **Paper scope:** Package design rationale, benchmarks vs raw rgee, worked examples in ecology/agriculture

### Consulting Portfolio

- Package demonstrates integration capability across R, Python, and cloud platforms
- Suitable for showcasing in Adelaide University research profile and Supremum Consulting portfolio

---

## 9. Timeline & Iteration Plan

```
Week  1–2  ████░░░░░░░░  Phase 1: Skeleton & infrastructure
Week  3–5  ████████░░░░  Phase 2: Core extraction engine
Week  5–6  ██████████░░  Phase 3: Caching & batch extraction
Week  7–8  ████████████  Phase 4: Extended datasets & polish
Week  8–10 ████████████  Phase 5: Documentation & vignettes
Week 10–12 ████████████  Phase 6: Testing, review & release
```

**Total estimated effort:** 8–12 weeks of active development (accounting for iteration and review cycles).

**Milestones:**

| Milestone | Target | Gate |
|---|---|---|
| M1: Skeleton passes R CMD check | End of Week 2 | CI green, installable |
| M2: Core extraction works for 6 datasets | End of Week 5 | Manual demo successful |
| M3: Caching + batch extraction complete | End of Week 6 | Benchmarks show cache speedup |
| M4: 12+ datasets, extensible registry | End of Week 8 | `gf_register()` tested |
| M5: Documentation complete, pkgdown live | End of Week 10 | All vignettes render |
| M6: v0.1.0 released | End of Week 12 | R CMD check clean, ≥80% coverage |

---

## 10. Post-Release Roadmap (Future Considerations)

- **Raster extraction:** Return `terra::SpatRaster` objects for spatial outputs (not just point values)
- **Time series mode:** Built-in temporal interpolation and gap-filling for extracted series
- **Async extraction:** Non-blocking GEE calls for very large requests
- **Shiny app:** Interactive dataset browser and extraction configurator
- **REST API backend:** Optional mode using GEE REST API directly (bypassing rgee/Python entirely) — would eliminate the Python dependency entirely if Google's REST API matures
- **Integration with `targets`:** Pipeline-friendly functions for reproducible workflows
