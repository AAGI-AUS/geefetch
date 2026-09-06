# geefetch 0.1.0

## Bug fixes

* The seven SLGA soil datasets failed on both routes because
  `CSIRO/SLGA` is an image collection, not an image; each dataset now
  reads its attribute image (`CSIRO/SLGA/CLY` and so on).
* Sentinel-2 extraction failed with "Unknown function: Image.Or"; the
  cloud mask now calls `Image.or`.
* Scene-based collections (Sentinel-2, Landsat) returned an arbitrary
  scene because no spatial filter preceded `Collection.first`. Every
  time-series request now filters the collection to images intersecting
  the requested region or points, and scene collections are mosaicked.
* `collect_gee_data()` now applies the same QA masks, `depth`/`stat`
  selection and NDVI computation as `read_gee()`. Previously the point
  route ignored `depth` and `stat` and returned raw reflectance for the
  NDVI datasets. The cache key now includes `depth` and `stat`.
* NDVI values outside [-1, 1] no longer appear at Landsat fill pixels;
  non-positive reflectances are masked before the ratio.
* `jsonlite` is back in Imports: httr2 (>= 1.3.0) no longer imports it,
  yet every JSON response parse needs it.

* `collect_gee_data()` no longer fails live point extraction with
  HTTP 400. The point set was sent to `Image.sampleRegions()` as a
  GeoJSON object inside `constantValue`, which the Earth Engine
  Expression grammar reads as a Dictionary rather than a
  FeatureCollection. Points are now built as a `Collection` of
  `Feature` invocations with `GeometryConstructors.Point` geometries,
  the form the service accepts.
* A Google Earth Engine service error message containing braces or
  backticks (for example, one quoting a project number or field name)
  reached the user garbled, because the text was passed to `cli` as
  part of a message template rather than as data. Service and
  condition text is now passed as data, so it reaches the user
  verbatim.
* A batch-extraction reply lacking a `point_id` property now aborts
  with a clear message, instead of aligning returned values to the
  requested points by position, which could silently attach a value
  to the wrong point.
* Calling the REST API with no Google Cloud project set now aborts
  with guidance, instead of forming a malformed `projects//...`
  request URL.
* `gee_auth()` now warns when no project is supplied and it falls
  back to the legacy `earthengine-legacy` project, which Earth Engine
  refuses for most accounts.
* The "region too large" warning from the internal grid builder now
  states the dataset's native pixel scale (in metres), the effective
  scale after resampling, and the resulting pixel dimensions, and
  suggests requesting a smaller region to keep the native resolution.
  Previously it gave only the resampled pixel count, with no
  indication of the resolution lost or how to avoid it.

# geefetch 0.0.0.9001 (2026-04-21)

Substantial institutional-compliance and governance uplift. No changes to
the extraction API. The package now meets all AAGI-canonical MUSTs from the
`/rpkg` v0.4.1 AAGI preset and all four mandatory-uplift Blockers (B1–B4).
Also fixes four real bugs in the live-API path that blocked end-to-end
extraction against a user-owned Google Cloud project.

## User-visible changes

* **R-Universe-first install.** README and the getting-started vignette now
  lead with the R-Universe install pattern:
  `install.packages("geefetch", repos = c("aagi-aus" = "https://aagi-aus.r-universe.dev", CRAN = "https://cran.r-project.org"))`.
  The dev-version fallback uses `pak::pak("AAGI-AUS/geefetch", subdir = "geefetch")`
  (replacing the previous `remotes::install_github` pattern).
* **Lifecycle badges** — every exported function now carries a `lifecycle`
  badge in its help page. All 17 package-authored exports are currently
  `experimental`; the four re-exports (`rast()`, `ext()`, `st_as_sf()`,
  `st_bbox()`) inherit upstream lifecycle from `terra` / `sf`. See the
  new `API_STABILITY.md` for the per-function catalogue.
* **`gee_auth()` + `vignette("geefetch")` rewritten around the
  quota-project model.** The vignette now front-loads a four-step pre-R
  setup (create GCP project → register with EE → enable EE API → pick one
  Google account for all steps) plus a decision tree for HTTP 403
  troubleshooting. `?gee_auth` documents why the project *number* should
  be passed instead of the ID. `gee_setup()` reprints the same checklist
  in-console. Together these close the "why did my setup take four
  hours?" gap that was surfaced during first-time live testing.

## Bug fixes

* **`X-Goog-User-Project` header now sent on every REST call.** Without
  this header, Google Earth Engine charges the OAuth token's default
  quota project (which is usually the project where the OAuth client
  happened to be registered) rather than the resource project in the
  URL. Users whose OAuth consent was granted under one project but whose
  resource project is different received HTTP 403 with a confusing error
  message naming the wrong project number. Setting
  `X-Goog-User-Project: <project>` forces the quota project to match the
  resource project. This was the load-bearing fix to make live extraction
  work against a user-owned Google Cloud project. Documented at
  <https://docs.cloud.google.com/docs/authentication/rest#set-quota-project>.

* **`.rest_compute_pixels()` no longer returns a `SpatRaster` pointing at
  a deleted tempfile.** The function created a tempfile, returned a
  file-backed raster, then `on.exit(unlink(tmp))` deleted the tempfile
  before the caller could use the raster. Downstream operations (disk
  cache write, `plot()`, `terra::values()`) failed with
  `[writeRaster] file does not exist`. Fixed by materialising the raster
  into memory via `r * 1` before returning — the returned object no
  longer depends on the tempfile's lifetime.

* Fixed a syntax error in `R/backend_rest.R` that would have blocked
  `R CMD check` and `devtools::document()`. The `cli::cli_warn()` call in
  `.build_grid()` used a bare `!` as a named-argument key (introduced by
  commit 019963e during an earlier cli-lint sweep); R's parser rejected
  this. Corrected to backtick-quoted `` `!` `` matching the
  quoted-key cleanup applied to other files (`cache.R`,
  `collect_gee_data.R`, `handler_registry.R`). Without this fix the
  package could not be loaded or documented.

* Fixed `rlang::arg_match(tolower(x))` pattern across ten files /
  eleven call sites. `rlang::arg_match()` needs a bare argument symbol
  to infer allowed values from the caller's formals; wrapping the
  argument in `tolower()` breaks that lookup with a cryptic
  `'arg' must be a symbol, not a function call` message, taking out
  17 tests. Restructured to two-statement form
  (`x <- tolower(x); x <- rlang::arg_match(x)`) that preserves the
  input case-normalisation intent. Also corrected a `to_lower` typo in
  `read_slga.R:70` that would error at runtime.

## Internal / governance

This release ships a comprehensive governance surface that was absent
at 0.0.0.9000. Most items have no user-facing runtime behaviour but are
load-bearing for CRAN / rOpenSci / R-Universe distribution, for
reviewer-defensibility, and for successor maintainers.

* **AAGI alignment** (M1, M2, M3, M5, M6, M8 from `presets/aagi.yml`):
  * `codemeta.json` (schema.org/codemeta-2.0), seeded from DESCRIPTION.
  * `COPYRIGHT` — logo carve-out for AAGI, GRDC, Curtin, UQ, Adelaide.
  * GRDC funding attribution (CUR2210-005OPX) in DESCRIPTION
    `Description:`.
  * DESCRIPTION `URL:` now lists both the repo and the pkgdown site
    (`https://aagi-aus.github.io/geefetch/`).
  * R-Universe registration patch for `AAGI-AUS/aagi-aus.r-universe.dev`
    emitted as `r-universe-registration.patch` (to be applied manually
    — not auto-committed).

* **Security / supply chain** (B1–B4 from `rubrics/mandatory_uplift.md`):
  * `CITATION.cff` (CFF-1.2.0) alongside the existing `inst/CITATION`.
  * `SECURITY.md` with a private-disclosure channel (GitHub advisory +
    maintainer email) and a 72 h acknowledgement SLA.
  * `.github/dependabot.yml` — weekly `github-actions` +
    `docker` (`.devcontainer/`) groups.
  * R-CMD-check matrix gains a `macos-14` (Apple Silicon) leg alongside
    `macos-latest`.

* **Code quality** (Tier 2 baseline):
  * Dropped unused `jsonlite` from `Imports:` — it was declared but
    never called in `R/` (httr2 handles all REST JSON internally).
    One test refactored to `unlist()` + `grepl()` instead.
  * Swept remaining quoted cli keys (`"v"=`, `"!"=`, `"x"=`) to bare /
    backtick-quoted forms, continuing the pattern from Sparks's 019963e.
  * `.lintr` + repo-root `.github/workflows/lint.yaml` now gate
    lintr-clean on every PR.
  * `inst/WORDLIST` seed for `devtools::spell_check()` covering GEE
    domain terms and dependency names.
  * `codecov.yml` with informational-only thresholds.
  * `tests/testthat/setup.R` sanitises auth env vars, disables the
    disk cache, pins locale for snapshot stability.
  * **`httptest2` suite skeleton** under
    `tests/testthat/test-backend_rest-http.R` — four mocked REST tests
    (200 / 401 / 429 / 403) that skip gracefully until cassettes are
    captured. Recapture procedure in `tests/testthat/README.md`.

* **Governance surface** (Tier 3 Should-fix):
  * `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1),
    `CONTRIBUTING.md` (with maintainer-competence matrix),
    `SUPPORT.md` (with honest maintenance-capacity block and
    abandonment protocol), `API_STABILITY.md` (per-function lifecycle
    catalogue).
  * `adr/0001-0004` at the repo root — Nygard-format ADRs covering
    the meta-decision, class-system choice (S3, not S7), Imports
    budget, and maintenance posture.
  * `.github/ISSUE_TEMPLATE/*.yml` YAML issue forms (bug, feature,
    config) replace the previous empty state; `blank_issues_enabled:
    false` routes general questions to Discussions.
  * `.github/PULL_REQUEST_TEMPLATE.md`, `.github/CODEOWNERS`,
    `.github/FUNDING.yml`.
  * `.github/workflows/revdep.yaml` and `dependency-review.yaml`.
  * `lifecycle` added to `Imports:` (documented exception in ADR 0003
    — metadata-only, does not count against the archetype-6 Imports
    cap of 10).

* **Hardening** (Tier 4 nice-to-have):
  * `.pre-commit-config.yaml` (repo root) — air + lintr + gitleaks +
    standard whitespace/yaml hooks.
  * `.devcontainer/` (repo root) — rocker-based image with the sf /
    terra / httr2 system-lib bundle and the dev toolchain pre-installed.
  * `.github/workflows/codeql.yaml` — weekly + push/PR scan of the
    actions-language surface.
  * `.github/workflows/attestations.yaml` — signed build provenance +
    tarball attachment on release.

## Acknowledgements

This release builds on eight commits from the `review/ahs` branch by
Adam H. Sparks (`c300561..4d2c7b9`):

* Added `air.toml` and reformatted the codebase with `air`.
* Completed the `match.arg()` → `rlang::arg_match()` migration across
  all 15 call sites (the 8f6ace8 commit message references
  `rlang::match_arg()`, a function that does not exist; the actual
  code is correct).
* Linted all `cli_*()` calls to bare-key style and type-normalised
  the `initial_delay` argument to integer.
* Normalised user inputs to consistent upper/lower-case conventions.
* Re-ran `devtools::document()`.

Supported by Curtin University and the Grains Research and Development
Corporation through GRDC Project CUR2210-005OPX.

# geefetch 0.0.0.9000

* Initial package skeleton with handler registry, validation, authentication,
  and caching infrastructure.
* Dataset catalogue with Tier 1 GEE collections (MODIS NDVI, MODIS LST,
  ERA5 temperature/precipitation, CHIRPS precipitation, SRTM elevation).
