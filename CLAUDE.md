# CLAUDE.md — geefetch

## Package Overview

- **Package**: geefetch
- **Purpose**: Python-free R interface for extracting spatio-temporal environmental covariates from Google Earth Engine
- **Organisation**: AAGI-AUS (GitHub)
- **Target repositories**: CRAN, rOpenSci
- **Publication targets**: JOSS (primary), Methods in Ecology and Evolution (application note)
- **Status**: Early development
- **Authors**: Max Moldovan (ORCID: 0000-0001-9680-8474), Adam H. Sparks (ORCID: 0000-0002-0061-8359)

## Architecture — Critical Context

This package follows **nert's architecture exactly**. When in doubt, check how nert does it:

- **Dispatcher pattern**: `read_gee()` → `.gee_resolve_id()` → `.gee_validate_args()` → `switch()` → internal handler. Mirrors nert's `read_tern()`.
- **Convenience aliases**: `read_modis_ndvi()`, `read_era5()`, etc. Thin wrappers with **named parameters** (not `...` forwarding). Each has its own roxygen2 page.
- **Batch extraction**: `collect_gee_data()` → `data.table`. Mirrors nert's `collect_tern_data()`.
- **Output types**: `read_*()` returns `terra::rast()`. `collect_*()` returns `data.table`. No exceptions.
- **Error handling**: `cli::cli_abort()` for all user-facing errors. `rlang::arg_match()` for enum parameters. `tryCatch()` with `cli::cli_warn()` + NA fallback in batch operations.

### Dual Backend (REST-first)

The package's key differentiator: **no Python required**.

- **REST API (default)**: `httr2` + `gargle` → GEE REST API v1 (`computePixels`, `computeFeatures`). Pure R.
- **rgee (fallback)**: For advanced server-side computation. `rgee` is in **Suggests only** — never loaded unless `backend = "rgee"` is explicitly requested.
- Every `requireNamespace("rgee")` call must include a helpful `cli::cli_abort()` guiding the user to either install rgee or switch to `backend = "rest"`.

### Authentication

- Uses `gargle` (same as googlesheets4, bigrquery, googledrive). No custom auth code.
- `gee_auth()` for OAuth / service account. `gee_status()` to check state.
- **Never store or log credentials.** Token caching is gargle's responsibility.

## Project-Specific Directives

- Primary data manipulation: `data.table` (no tidyverse in Imports)
- Spatial stack: `terra` (raster), `sf` (vector). No `stars`, no `raster` (retired).
- HTTP: `httr2` (not `httr`). All REST calls go through internal `.rest_request()` with retry logic.
- Auth: `gargle`. No custom OAuth implementations.
- Caching: `digest` (SHA256 keys) + `fst` (Suggests, fall back to `saveRDS`). Cache dir via `tools::R_user_dir("geefetch", "cache")`.
- JSON: `jsonlite` for GEE REST API response parsing.
- User messaging: `cli` exclusively. No `message()`, no `cat()`, no `warning()`.
- Bundled data: `inst/extdata/example_sites.csv` — small set of Australian point locations for examples.
- Language: en-AU (colour, behaviour, optimise).

### Non-Obvious Constraints

- **Box cloud sync**: Files may be on Box. Never `R CMD INSTALL` from synced source dir — always `R CMD build` first, then install the tarball.
- **GEE project ID**: REST API requires a Google Cloud project with Earth Engine enabled. `gee_setup()` must guide users through this.
- **Rate limits**: GEE REST API returns 429 on overuse. All REST calls must use exponential backoff (httr2's built-in retry).
- **CRAN and credentials**: No vignette or example may require live GEE access. Use precompiled vignettes (`!precompile.R` pattern from nert) and `\examplesIf{interactive()}`.

## Development Workflow

1. Inspect package structure and metadata before editing code.
2. Make focused changes in `R/`, tests, vignettes, roxygen comments.
3. Regenerate docs: `devtools::document()`.
4. Fast local loop: `pkgload::load_all()` → targeted `devtools::test()` → `lintr::lint_package()`.
5. Broader validation: `devtools::check()`.
6. Build tarball: `R CMD build .` (never install directly from Box-synced source).
7. Final gate: `R CMD check --as-cran geefetch_*.tar.gz`.
8. Verify vignettes: `browseVignettes("geefetch")` after tarball install.

### When Adding a New GEE Dataset

1. Add entry to `.GEE_ALIASES` in `handler_registry.R`.
2. Add metadata to `.GEE_META` in `handler_registry.R`.
3. Write internal handler `.read_gee_{name}()` in `handlers.R`.
4. Write convenience alias `read_{name}()` in its own `read_{name}.R` file with full roxygen2.
5. Add the alias to `@family GEE readers`.
6. Add validation rules to `.gee_validate_args()`.
7. Add support in `collect_gee_data()` (time-series vs static classification).
8. Write unit tests (mocked) + integration test (live, `skip_on_cran()`).
9. Update `gee_datasets()` output and `_pkgdown.yml` grouping.
10. Update the "Batch Extraction" vignette if column naming is non-trivial.

## Code Style Enforcement

- Formatter: Air (`air.toml` in project root). Fall back to `styler` if Air not configured.
- Linter: `lintr` — run in CI and before any PR/submission.
- Naming: `snake_case` throughout. Pipe-friendly APIs (data/geometry as first argument where sensible).
- Internal functions: `.dot_prefix_snake_case` (e.g., `.read_gee_modis_ndvi()`, `.cache_get()`).
- roxygen2: Markdown enabled. Every export must have `@description`, `@param` (all), `@returns`, `@examplesIf{interactive()}`, `@family`, `@seealso`. Dataset functions also need `@references` with DOI and `@section Data availability:`.

## Testing Requirements

- Framework: `testthat` edition 3, parallel execution enabled.
- **Offline tests (default)**: Use `httptest2` to mock REST API responses. These run on CRAN and CI without credentials.
- **Live integration tests**: Guarded by `skip_on_cran()` + `skip_if_not(gee_status()$authenticated)`. Run in CI with a service account secret.
- Coverage targets: ≥80% line coverage. All exported functions must have at least one test.
- Snapshot tests: Use for `cli` error/warning messages and `gee_status()` printed output.
- No `vdiffr` — this package produces no plots.
- No Shiny — not applicable.

## CI Matrix

- GitHub Actions via `usethis::use_github_action("check-standard")`.
- OS: Ubuntu (latest), macOS (latest), Windows (latest).
- R versions: release, devel, oldrel.
- Additional workflows:
  - test-coverage (`covr`) with Codecov upload
  - pkgdown deployment to GitHub Pages
  - lint check
  - **Live GEE integration tests** (Ubuntu + release only, service account JSON in GitHub secret `GEE_SERVICE_ACCOUNT_KEY`)
- Pre-submission: win-builder (release + devel), R-hub.

## Educational Website & User Onboarding

- Use `pkgdown` as the site generator, deployed to GitHub Pages via CI.
- Required pages:
  - **Home**: One-paragraph purpose, key differentiator (no Python), install command, "Get Started" link.
  - **Get Started**: Authentication → first extraction → point extraction → batch workflow. Under 10 minutes.
  - **Articles**: All 3 vignettes rendered as articles.
  - **FAQ / Troubleshooting**: Auth failures, REST vs rgee backend choice, cache management, GEE quota issues.
- `_pkgdown.yml` function grouping:
  - GEE Readers (`read_gee`, all `read_*` aliases)
  - Batch Extraction (`collect_gee_data`)
  - Authentication (`gee_auth`, `gee_status`, `gee_setup`)
  - Utilities (`gee_datasets`, `gee_register_dataset`, `gee_clear_cache`)

## Scope Boundaries

geefetch **does**:
- Extract point values and rasters from GEE collections
- Cache results to disk
- Provide convenience aliases for common datasets
- Batch-extract across locations × dates × datasets → `data.table`

geefetch **does NOT**:
- Do server-side computation (composites, band math, classification) — use `rgee` directly
- Provide mapping or visualisation — use `terra::plot()`, `ggplot2` + `tidyterra`, `leaflet`
- Model environmental data — use `nlme`, `mgcv`, `ranger`, etc.
- Replace rgee — it complements rgee for the common extraction case
- Access non-GEE data sources — that's `nert` (TERN) or other specialised packages

## Definition of Done

A change is not complete until:

- [ ] `R CMD build` succeeds
- [ ] `R CMD check --as-cran` on tarball: 0 errors, 0 warnings, 0 notes
- [ ] Tests comprehensive and passing (mocked offline + live integration where applicable)
- [ ] Documentation: roxygen2 complete, examples runnable, vignettes render
- [ ] `pkgdown::build_site()` succeeds
- [ ] CI green on all 3 OS
- [ ] No secrets, credentials, or API keys in committed code
- [ ] NEWS.md updated for user-visible changes
- [ ] New datasets follow the 10-step checklist above

## References

- GEE REST API: https://developers.google.com/earth-engine/reference/rest
- GEE Data Catalog: https://developers.google.com/earth-engine/datasets
- gargle (R Google auth): https://gargle.r-lib.org/
- nert (architectural template): https://github.com/AAGI-AUS/nert
- rgee: https://r-spatial.github.io/rgee/


additional data sources, to consider for inclusion.

Rank,Data Source,What It Provides,R Integration Quality,Research / Practical Value,Recommended Integration Style,Why It Complements GEE + TERN
1,SoilGrids 2.0 / OpenLandMap,"Global soil properties (SOC, pH, texture, bulk density, etc.) at 250 m or 30 m resolution","Excellent (soilgrids, terra)","Extremely high (soil science, agriculture, carbon, ecology)",Lightweight wrapper: get_soilgrids() or get_openlandmap(),Fills GEE’s major soil data gap; excellent with TERN’s Australian focus
2,GBIF occurrence data,2.2+ billion global biodiversity records,Outstanding (rgbif package),"Very high (species distribution modelling, ecology, conservation)",High-level function: get_gbif_occ() returning sf,Adds biological layer to remote sensing data
3,ERA5-Land (Copernicus),"High-resolution climate reanalysis (~9 km, hourly, 1950–present)",Very good (ecmwfr package),"High (climate impact, hydrology, ecology)",Wrapper: get_era5_land(),Best free climate time-series; superior to many GEE climate products
4,Copernicus Sentinel-2/3,Free 10 m optical + SAR imagery,"Good (sen2r, CDSE tools)","High (land cover, vegetation, change detection)",Optional: get_sentinel(),High-resolution complement to GEE
5,CHELSA / WorldClim,Bioclimatic variables at 1 km resolution,Easy (direct terra download),Medium-high (species distribution modelling),Simple: get_bioclim(),"Classic, widely used baseline layers"

