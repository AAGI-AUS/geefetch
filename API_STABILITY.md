# API stability — geefetch

This package follows [SemVer](https://semver.org/). Per-function API
stability is tracked via the [lifecycle](https://lifecycle.r-lib.org/)
package; every exported function carries a lifecycle badge in its
roxygen `@description`.

## Lifecycle stages

- **Stable:** no breaking changes without a major version bump.
- **Experimental:** API may change in a minor release, with one
  [`lifecycle::deprecate_warn()`](https://lifecycle.r-lib.org/reference/deprecate_soft.html)
  cycle before the break.
- **Superseded:** still works and is still maintained, but we’d write it
  differently today; a replacement is documented.
- **Deprecated:** hard warning; scheduled for removal.

## Current status (0.0.0.9001 dev)

At pre-release every exported function is **experimental**. A function
flips to **stable** no earlier than the first minor release that has
validated its signature on live GEE traffic for ≥ 1 month.

| Function                                                                                          | Lifecycle    | Since      | Notes                                                                                                                  |
|---------------------------------------------------------------------------------------------------|--------------|------------|------------------------------------------------------------------------------------------------------------------------|
| **Dispatcher + readers**                                                                          |              |            |                                                                                                                        |
| [`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)                         | experimental | 0.0.0.9000 | Central dispatcher. Signature likely stable post-0.1.0 once the `bands`/`qa_mask`/`backend` parameter surface settles. |
| [`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md)           | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md)             | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md)                       | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md)                   | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md)                       | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md)                       | experimental | 0.0.0.9000 | `@family GEE readers`. Australian SLGA soil stack.                                                                     |
| [`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md)             | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md)                 | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| [`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)             | experimental | 0.0.0.9000 | `@family GEE readers`                                                                                                  |
| **Batch extraction**                                                                              |              |            |                                                                                                                        |
| [`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)         | experimental | 0.0.0.9000 | Returns `data.table`. Column naming convention may tighten in 0.1.0 for multi-dataset consistency.                     |
| **Authentication**                                                                                |              |            |                                                                                                                        |
| [`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md)                         | experimental | 0.0.0.9000 | Thin wrapper over [`gargle::token_fetch()`](https://gargle.r-lib.org/reference/token_fetch.html).                      |
| [`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)                     | experimental | 0.0.0.9000 | Print-method output format is subject to change.                                                                       |
| [`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)                       | experimental | 0.0.0.9000 | Interactive-only.                                                                                                      |
| **Utilities**                                                                                     |              |            |                                                                                                                        |
| [`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)                 | experimental | 0.0.0.9000 | Returns `data.table`.                                                                                                  |
| [`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md) | experimental | 0.0.0.9000 | Side-effect: mutates internal environment.                                                                             |
| [`gee_clear_cache()`](https://aagi-aus.github.io/geefetch/reference/gee_clear_cache.md)           | experimental | 0.0.0.9000 |                                                                                                                        |
| **Re-exports (upstream stability applies)**                                                       |              |            |                                                                                                                        |
| [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)                           | re-exported  | 0.0.0.9000 | Stability tracks `terra`.                                                                                              |
| [`terra::ext()`](https://rspatial.github.io/terra/reference/ext.html)                             | re-exported  | 0.0.0.9000 | Stability tracks `terra`.                                                                                              |
| [`sf::st_as_sf()`](https://r-spatial.github.io/sf/reference/st_as_sf.html)                        | re-exported  | 0.0.0.9000 | Stability tracks `sf`.                                                                                                 |
| [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html)                          | re-exported  | 0.0.0.9000 | Stability tracks `sf`.                                                                                                 |

Regenerate this table from the roxygen `@lifecycle` tags + `NAMESPACE`
when it goes out of date (`data-raw/regen_api_stability.R`, planned).

## Deprecation cycle

Every deprecation follows at least three releases:

1.  `lifecycle::deprecate_warn("X.Y.Z", "old_fn()")` — soft warning.
2.  `lifecycle::deprecate_stop("X.Y+1.0", "old_fn()")` — hard error.
3.  Source removal in `X.Y+2.0` (or the next major, whichever comes
    first).

Each deprecation decision is recorded as an ADR under `adr/`.

## Supported versions

| Version                  | Status              | Supported until     |
|--------------------------|---------------------|---------------------|
| 0.0.0.9xxx dev           | current development | next tagged release |
| (no tagged releases yet) | —                   | —                   |

Post-0.1.0 the support policy will be: latest minor + previous minor
both receive security and correctness patches; older versions
best-effort.

## Dependency version policy

- `Imports:` version floors tested in CI (`test-coverage.yaml`).
- Floors raised only in minor+ releases; never in a patch.
- Heavy new deps require an ADR before addition (see
  `adr/0003-imports-budget.md`).
- At time of writing (0.0.0.9001) Imports count sits at the archetype-6a
  soft cap (10). Any new Imports dep needs explicit ADR justification.
