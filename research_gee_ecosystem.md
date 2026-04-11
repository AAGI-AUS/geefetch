# Google Earth Engine R Ecosystem: Comprehensive Research Report

**Date:** 2026-04-11
**Purpose:** Landscape analysis for designing a best-in-class GEE R package (geefetch)
**Author:** Max Moldovan (research compiled with AI assistance)

---

## 1. rgee Package: Current State

### Metadata

| Field | Value |
|-------|-------|
| **CRAN Version** | 1.1.8 |
| **Published** | 2025-10-15 |
| **Dev Version** | 1.1.8.9000 (GitHub) |
| **Original Author** | Cesar Aybar (csaybar) |
| **Current Maintainer** | Matthieu Stigler (as of v1.1.8) |
| **GitHub Stars** | 774 |
| **Open Issues** | 62 |
| **Last GitHub Push** | 2026-04-06 |
| **License** | Apache 2.0 |
| **R Dependency** | >= 3.3.0 |

### Architecture

rgee wraps the Earth Engine **Python** API via `reticulate`. The chain is:

```
R code -> reticulate -> Python earthengine-api -> JSON -> GEE REST API
```

This means rgee **requires a working Python environment** with `earthengine-api` and `numpy` installed. This is the single biggest source of user friction.

### Key Functions (Complete Reference)

**Initialisation & Auth:**
- `ee_Initialize()` — Authenticate and initialise (the #1 source of issues)
- `ee_Authenticate()` — OAuth2 authorisation prompt
- `ee_install()` — Create isolated Python venv with dependencies
- `ee_check()` / `ee_check_python()` / `ee_check_credentials()` — Diagnostic checks
- `ee_clean_user_credentials()` — Wipe cached credentials

**Data Extraction:**
- `ee_extract()` — Extract values from Images/ImageCollections at geometries (the workhorse function)
  - Supports `ee$Reducer` functions
  - Methods: `"getInfo"` (default, synchronous), `"drive"`, `"gcs"`
  - `lazy = TRUE` for async/batch via `future`

**Image Download (EE -> R):**
- `ee_as_rast()` — EE Image -> terra SpatRaster (preferred, newer)
- `ee_as_raster()` — EE Image -> raster (deprecated in favour of terra)
- `ee_as_stars()` — EE Image -> stars object
- `ee_as_thumbnail()` — Quick preview as spatial grid
- `ee_imagecollection_to_local()` — Download entire ImageCollection

**Vector Conversion:**
- `ee_as_sf()` — EE FeatureCollection -> sf
- `sf_as_ee()` — sf -> EE object

**Export (to cloud):**
- `ee_image_to_drive()` / `ee_image_to_gcs()` / `ee_image_to_asset()`
- `ee_table_to_drive()` / `ee_table_to_gcs()` / `ee_table_to_asset()`

**Upload:**
- `stars_as_ee()` / `raster_as_ee()` — R raster -> EE Image
- `gcs_to_ee_image()` / `gcs_to_ee_table()` — GCS -> EE Asset

**Asset Management:**
- `ee_manage_*()` family — create, delete, list, copy, move, quota, permissions

**Visualisation:**
- `Map` — R6 object for interactive leaflet-based display
- `+` / `|` operators for combining map layers

**Date Utilities:**
- `eedate_to_rdate()` / `rdate_to_eedate()` / `ee_get_date_img()` / `ee_get_date_ic()`

**Utilities:**
- `ee_print()` — Metadata display for EE objects
- `ee_utils_dataset_display()` — Search EE Data Catalogue
- `ee_utils_sak_copy()` / `ee_utils_sak_validate()` — Service account key management

### Maintenance Status

- **Maintainer changed** in v1.1.8 (Oct 2025) from Cesar Aybar to Matthieu Stigler
- Last formal CRAN release was v1.1.3 (March 2022); then jumped to 1.1.7 (Sep 2023) and 1.1.8 (Oct 2025) — **sporadic release cadence**
- Active on GitHub (last push April 2026), but dev branch only has one minor fix (#396)
- v1.1.8 added testthat framework, dataset update automation, fixed several init bugs
- **No tagged GitHub releases since v1.1.3** (March 2022) — CRAN releases happen without GitHub tags

### Assessment

| Aspect | Rating | Notes |
|--------|--------|-------|
| Completeness | Good | Wraps full EE API |
| Reliability | Poor | Auth/init issues dominate bug reports |
| Performance | Poor | `ee_extract` slow for large datasets; Python overhead |
| UX / Ergonomics | Fair | Not idiomatic R; feels like Python-in-R |
| Maintenance | Fair | New maintainer; sporadic releases |
| Installation | Poor | Python/reticulate setup is a major barrier |

---

## 2. Competing/Related R Packages

### rgeeExtra (r-earthengine/rgeeExtra)

| Field | Value |
|-------|-------|
| Stars | 46 |
| Last Push | 2023-11-23 (stale — 2.5 years old) |
| Status | **Effectively abandoned** |
| CRAN | Not on CRAN (GitHub only) |

- Built on `ee_extra` (Python), extends rgee with spectral indices, cloud masking, preprocessing
- Aimed to be the R equivalent of eemont
- **Dead project** — no updates in 2.5 years

### tidyrgee (r-tidy-remote-sensing/tidyrgee)

| Field | Value |
|-------|-------|
| Stars | 49 |
| Last Push | 2025-11-17 |
| CRAN | Yes |
| Status | Low activity, niche |

- Provides dplyr-style verbs (`filter`, `group_by`, `summarise`, `select`, `mutate`) for EE ImageCollections
- Creates a `tidyee` object wrapping `ee$ImageCollection` with a virtual table (vrt)
- **Strengths:** Idiomatic R syntax; pipe-friendly
- **Weaknesses:** Still depends on rgee (inherits all its problems); limited scope (ImageCollections only); small community

### rgeedim (brownag/rgeedim)

| Field | Value |
|-------|-------|
| Stars | 53 |
| Last Push | 2026-04-01 (active) |
| CRAN | Yes |
| Status | **Actively maintained** |

- R wrapper for Python `geedim` package
- Focused on **search, composite, and download** workflows
- Handles cloud masking and compositing for Landsat/Sentinel
- Splits large downloads into tiles and reassembles
- Still requires Python (via reticulate), but simpler scope

### ee_extra (r-earthengine/ee_extra)

| Field | Value |
|-------|-------|
| Stars | 66 |
| Last Push | 2026-04-01 (active) |
| Status | Python package that powers rgeeExtra and eemont |

- The "ninja Python package that unifies the GEE ecosystem"
- Provides spectral indices, cloud masking, preprocessing
- Shared foundation between R (rgeeExtra) and Python (eemont)

### Summary Table

| Package | CRAN | Python Dep | Active | Scope | Idiomatic R |
|---------|------|------------|--------|-------|-------------|
| rgee | Yes | Yes (reticulate) | Fair | Full EE API wrapper | No |
| rgeeExtra | No | Yes | Dead | Extended methods | No |
| tidyrgee | Yes | Yes (via rgee) | Low | Tidy verbs for IC | Yes |
| rgeedim | Yes | Yes (reticulate) | Yes | Download/composite | Partial |

**Key gap: No R package accesses GEE without Python.**

---

## 3. Python GEE Ecosystem (State of the Art)

### geemap (gee-community/geemap) — The Gold Standard

| Field | Value |
|-------|-------|
| Stars | **3,920** |
| Last Push | 2026-04-10 (very active) |
| Author | Qiusheng Wu (Professor, U of Tennessee) |
| Book | "Geospatial Data Science with Earth Engine and Geemap" |

**Features R completely lacks:**
- Interactive Jupyter-based maps with `ipyleaflet`/`ipywidgets`
- Split-panel maps for temporal comparison
- Inspector Tool (click map -> query pixel values)
- Time-series inspector and time slider
- Built-in charting (histograms, scatter plots, bar charts)
- JS-to-Python code converter
- Layer manager with transparency controls
- Built-in legends
- COG and STAC layer support
- Export to various formats including animated GIFs
- 100+ tutorial notebooks

### eemont (davemlz/eemont)

| Field | Value |
|-------|-------|
| Stars | 446 |
| Last Push | 2026-04-01 (active) |

**Key features:**
- One-line preprocessing: `image.preprocess()` handles cloud masking + scaling + offset
- Overloaded operators (`+`, `-`, `*`, `/`) for image math
- Spectral index computation (NDVI, EVI, etc.) built in
- Extends `ee.Image` and `ee.ImageCollection` with convenience methods

### Xee (google/Xee) — Official Google Package

| Field | Value |
|-------|-------|
| Stars | 349 |
| Last Push | 2026-04-08 (active) |

**This is a game-changer:**
- Xarray backend for Earth Engine
- Opens `ee.ImageCollection` as lazy `xarray.Dataset`
- Integrates with Dask for parallel/distributed processing
- Export to Zarr (cloud-optimised) with ~25 lines of code
- Can export terabytes via Dataflow in parallel
- Uses high-volume endpoint automatically
- **Bridges GEE with the entire scientific Python stack**

### geedim (leftfield-geospatial/geedim)

| Stars | 200+ | Active |
- CLI + Python API for search/composite/download
- Automatic tile splitting for large images
- Built-in cloud masking for Landsat/Sentinel

### Python Advantages Over R (Summary)

| Capability | Python | R (rgee) |
|------------|--------|----------|
| Interactive maps | geemap (excellent) | Map R6 object (basic) |
| Split-panel comparison | Yes | No |
| Inspector/click tools | Yes | No |
| Time series charts | Yes (built-in) | Manual |
| JS code converter | Yes | No |
| One-line preprocessing | eemont | No (manual) |
| Spectral indices | eemont (150+) | Manual |
| Xarray/Dask integration | Xee (native) | No equivalent |
| Cloud-native export (Zarr) | Yes | No |
| Tutorials/notebooks | 100+ | ~5 vignettes |
| Community size | 5x-10x larger | Small |

---

## 4. Common GEE Workflows (What Researchers Actually Do)

Based on literature review and community analysis, ranked by frequency:

### Tier 1 — Very Common (daily use)

1. **Point/polygon value extraction** — Extract raster values at point locations or within polygons across time. The single most common operation.
2. **Time series extraction** — NDVI, EVI, LST, precipitation time series for locations/regions. Core of agricultural and ecological monitoring.
3. **Land use/land cover (LULC) classification** — Random Forest and SVM on Landsat/Sentinel composites. The dominant published use case.
4. **Cloud-free composite generation** — Temporal compositing with cloud/shadow masking. Prerequisite for almost everything.

### Tier 2 — Common (weekly use)

5. **Raster/image download** — Download processed imagery as GeoTIFF for local analysis.
6. **Vegetation index computation** — NDVI, EVI, SAVI, etc. from multispectral imagery.
7. **Change detection** — Before/after comparison, trend analysis.
8. **Zonal statistics** — Mean, sum, percentile of raster values within administrative boundaries or field plots.

### Tier 3 — Specialised

9. **Climate/weather data extraction** — ERA5, CHIRPS, TerraClimate for study sites.
10. **Terrain analysis** — Elevation, slope, aspect from SRTM/ALOS.
11. **Water body mapping** — JRC Global Surface Water, NDWI.
12. **Fire/burn mapping** — MODIS/VIIRS fire products, dNBR.
13. **Soil property extraction** — OpenLandMap, SoilGrids.

### Key Insight for geefetch Design

The **overwhelming majority** of R users want:
- Extract values at points/polygons for a date range -> return a `data.table`/`data.frame`
- Get a cloud-free composite -> download as GeoTIFF
- Compute vegetation/spectral indices -> extract time series

These are **not** complex GEE computations. They are **data fetching and extraction** tasks that could be handled via the REST API directly, without the full GEE computation graph.

---

## 5. Known Pain Points with rgee

### Categorised from GitHub Issues (62 open, 400+ total)

#### P0 — Authentication & Initialisation (>50% of all issues)

The **most commented issues** in the entire repo are all about `ee_Initialize()` failing:

| Issue | Comments | Problem |
|-------|----------|---------|
| #290 | 36 | py_call_impl error |
| #355 | 26 | Credentials immediately expired |
| #269 | 20 | ee_Initialize() fails |
| #353 | 19 | Credential expiry |
| #91 | 19 | reticulate refuses to connect |
| #291 | 14 | Tries to auth even when already authed |
| #151 | 14 | numpy not installed |
| #369 | 13 | ee_Initialize() error |
| #271 | 12 | ee_Initialize() fails |
| #270 | 12 | ee_Initialize() on Ubuntu server fails |

**Root causes:**
- Python environment discovery/configuration is fragile
- Credential caching/refresh logic is unreliable
- Google's auth changes (OAuth client configs, Cloud Project requirements) break rgee
- reticulate version mismatches cause silent failures
- conda vs venv vs system Python confusion

#### P1 — Python/reticulate Dependency

- `ee_install()` frequently fails or creates broken environments
- Windows users have particular difficulty with Python path resolution
- conda environments can get OPENSSL version conflicts (#397)
- Users on servers/HPC face non-interactive auth challenges (#386)
- Version checking code breaks on unusual Python configs (#385, #375)

#### P2 — Performance

- `ee_extract()` becomes **extremely slow in loops** after several runs (#185)
- Large datasets require switching to `via = "drive"` or `via = "gcs"`, adding complexity
- No support for high-volume endpoint (#252 — open feature request)
- No parallel/batch extraction built in
- Python serialisation overhead on every call

#### P3 — Data Transfer

- Google Drive integration intermittently broken (#360)
- Large GeoTIFFs get split unexpectedly (#371)
- `ee_as_rast()` produces NaN values (#356)
- No direct `data.table` output option
- No caching layer

#### P4 — Documentation & UX

- rgee book is offline (#358)
- API feels like transliterated Python, not idiomatic R
- No pipe-friendly workflow
- Error messages are often opaque Python tracebacks
- Dataset discovery is cumbersome

---

## 6. Authentication Methods

### Current GEE Auth Options (as of April 2026)

| Method | Use Case | How It Works |
|--------|----------|--------------|
| **OAuth2 (interactive)** | Local dev, notebooks | Browser popup, stores refresh token locally |
| **Service Account** | Servers, automation, REST API | JSON key file, no browser needed |
| **Application Default Credentials (ADC)** | Cloud VMs (GCE, Cloud Run) | Automatic from VM metadata |
| **gcloud CLI** | Any (requires gcloud installed) | Uses gcloud's cached credentials |
| **Colab auth** | Google Colab | Automatic Colab-specific flow |

### Auth Modes in `ee.Authenticate()`

| `auth_mode` | Environment | Notes |
|-------------|-------------|-------|
| `colab` | Google Colab | Auto-detected |
| `localhost` | Local machine without gcloud | Opens browser |
| `gcloud` | Any with gcloud CLI | Most robust |
| `notebook` | Remote Jupyter | Generates URL to visit |

### Critical 2025-2026 Changes

- **Cloud Project requirement:** All EE operations now require a registered Google Cloud Project
- **Noncommercial verification:** Projects registered before April 15, 2025 must verify eligibility
- **Quota tiers:** All noncommercial projects must select a quota tier by **April 27, 2026**, or default to Community Tier
- **Community Tier limits:** 20 concurrent high-volume API requests

### For a New R Package (geefetch)

The **simplest, most robust auth path** would be:
1. **Service account** (JSON key) for headless/automated use -> direct REST API calls
2. **OAuth2 via gargle/httr2** for interactive use -> native R token management, no Python
3. **ADC** for cloud deployment -> automatic, zero config

All three can be handled **entirely in R** using `gargle` + `httr2`, bypassing Python completely.

---

## 7. GEE REST API: Direct Access Potential

### API Versions

| Version | Status | Key Endpoints |
|---------|--------|---------------|
| **v1** | Stable/production | Assets, exports, value.compute, table.computeFeatures |
| **v1alpha** | Preview | image.computePixels (the key one for pixel extraction) |
| **v1beta** | Beta | thumbnails.getPixels |

### Key Endpoints for geefetch

| Endpoint | Method | Purpose | Limits |
|----------|--------|---------|--------|
| `projects.image.computePixels` | POST | Compute + return pixel tile | 48MB uncompressed, 32K px per dim, 1024 bands |
| `projects.table.computeFeatures` | POST | Compute features from tables | Returns GeoJSON in EPSG:4326 |
| `projects.value.compute` | POST | Arbitrary computation result | General-purpose |
| `projects.assets.getPixels` | GET | Fetch raw pixels from asset | 48MB, 32K px, 1024 bands |
| `projects.image.export` | POST | Batch export to Drive/GCS/Asset | Async task |
| `projects.table.export` | POST | Batch export table | Async task |
| `projects.assets.*` | Various | CRUD for assets | — |

### High-Volume Endpoint

- URL: `https://earthengine-highvolume.googleapis.com`
- Designed for **automated, high-throughput, simple queries**
- Higher latency per request but supports more concurrent requests
- Community Tier: 20 concurrent; Professional: 500 concurrent
- **Ideal for point extraction at scale**

### Feasibility of Python-Free R Package

**YES — this is technically feasible and would be a major differentiator.**

The approach:
1. Use `httr2` for HTTP requests to the REST API
2. Use `gargle` for OAuth2/service account auth
3. Construct EE expression JSON directly (the REST API accepts serialised computation graphs)
4. Use `computePixels` for raster extraction at points
5. Use `computeFeatures` for vector/table operations
6. Use export endpoints for large batch jobs
7. Use high-volume endpoint for throughput

**Challenges:**
- Must construct EE computation graph JSON manually (or build a mini expression builder)
- `computePixels` is in **v1alpha** — could change (though it's been stable for years)
- Complex EE operations (classifiers, reducers, joins) require deep graph serialisation
- Google provides no R client library and limited REST API documentation

**Pragmatic hybrid strategy:**
- Use REST API directly for common operations (extraction, download, compositing)
- Keep optional reticulate/rgee fallback for complex/uncommon operations
- This covers 90%+ of real-world use cases without Python

---

## 8. Strategic Opportunity Map

### What's Missing in the R Ecosystem

| Gap | Impact | Difficulty |
|-----|--------|------------|
| Python-free GEE access | **Critical** | High (REST API integration) |
| Reliable authentication | **Critical** | Medium (gargle handles most of it) |
| One-line extraction to data.table | **High** | Medium |
| Built-in caching layer | **High** | Medium |
| Pre-built dataset recipes | **High** | Low-Medium |
| Spectral index library | Medium | Low (port from eemont/ee_extra) |
| Cloud masking presets | Medium | Low-Medium |
| Pipe-friendly tidy API | Medium | Low |
| Parallel extraction | **High** | Medium |
| Interactive visualisation | Medium | High (not core to data extraction) |

### Competitive Position for geefetch

If geefetch can deliver:
1. **Zero Python dependency** (REST API + httr2 + gargle)
2. **One-function extraction** (point values -> data.table in one call)
3. **Reliable auth** (gargle-managed, no credential confusion)
4. **Caching** (don't re-download what you already have)
5. **Pre-built recipes** for common datasets (NDVI, climate, terrain, soil)
6. **Batch/parallel extraction** with progress reporting

...it would be **immediately and dramatically better** than anything currently available in R, and would address every major pain point in the ecosystem.

---

## Sources

- [rgee GitHub Repository](https://github.com/r-spatial/rgee)
- [rgee CRAN Page](https://cran.r-project.org/package=rgee)
- [rgee Function Reference](https://r-spatial.github.io/rgee/reference/index.html)
- [rgee Changelog](https://r-spatial.github.io/rgee/news/index.html)
- [tidyrgee GitHub](https://github.com/r-tidy-remote-sensing/tidyrgee)
- [tidyrgee CRAN](https://cran.r-project.org/web/packages/tidyrgee/index.html)
- [rgeeExtra GitHub](https://rdrr.io/github/r-earthengine/rgeeExtra/)
- [rgeedim GitHub](https://github.com/brownag/rgeedim)
- [ee_extra GitHub](https://github.com/r-earthengine/ee_extra)
- [geemap GitHub](https://github.com/gee-community/geemap)
- [geemap Documentation](https://geemap.org/)
- [eemont GitHub](https://github.com/davemlz/eemont)
- [Xee (Google)](https://github.com/google/Xee)
- [geedim Python](https://github.com/leftfield-geospatial/geedim)
- [GEE REST API Reference](https://developers.google.com/earth-engine/reference/rest)
- [GEE Authentication Guide](https://developers.google.com/earth-engine/guides/auth)
- [GEE High-Volume Endpoint](https://developers.google.com/earth-engine/cloud/highvolume)
- [GEE computePixels](https://developers.google.com/earth-engine/apidocs/ee-data-computepixels)
- [GEE computeFeatures](https://developers.google.com/earth-engine/apidocs/ee-data-computefeatures)
- [GEE Service Accounts](https://developers.google.com/earth-engine/guides/service_account)
- [GEE Access & Registration](https://developers.google.com/earth-engine/guides/access)
- [rgee Issue #185 — ee_extract slow](https://github.com/r-spatial/rgee/issues/185)
- [rgee Issue #252 — High-volume endpoint request](https://github.com/r-spatial/rgee/issues/252)
- [rgee Issue #355 — Credentials expired](https://github.com/r-spatial/rgee/issues/355)
- [LULC Review with GEE (MDPI)](https://www.mdpi.com/2220-9964/14/11/416)
- [GEE Best Practices (rgee)](https://r-spatial.github.io/rgee/articles/rgee03.html)
