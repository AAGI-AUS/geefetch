# API stability — geefetch

This package follows [SemVer](https://semver.org/). Per-function API stability
is tracked via the [lifecycle](https://lifecycle.r-lib.org/) package; every
exported function carries a lifecycle badge in its roxygen `@description`.

## Lifecycle stages

- **Stable:** no breaking changes without a major version bump.
- **Experimental:** API may change in a minor release, with one
  `lifecycle::deprecate_warn()` cycle before the break.
- **Superseded:** still works and is still maintained, but we'd write it
  differently today; a replacement is documented.
- **Deprecated:** hard warning; scheduled for removal.

## Current status (0.0.0.9001 dev)

At pre-release every exported function is **experimental**. A function
flips to **stable** no earlier than the first minor release that has
validated its signature on live GEE traffic for ≥ 1 month.

| Function | Lifecycle | Since | Notes |
|---|---|---|---|
| **Dispatcher + readers** | | | |
| `read_gee()` | experimental | 0.0.0.9000 | Central dispatcher. Signature likely stable post-0.1.0 once the `bands`/`qa_mask`/`backend` parameter surface settles. |
| `read_modis_ndvi()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_modis_lst()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_era5()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_chirps()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_srtm()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_slga()` | experimental | 0.0.0.9000 | `@family GEE readers`. Australian SLGA soil stack. |
| `read_sentinel2()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_landsat()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| `read_worldclim()` | experimental | 0.0.0.9000 | `@family GEE readers` |
| **Batch extraction** | | | |
| `collect_gee_data()` | experimental | 0.0.0.9000 | Returns `data.table`. Column naming convention may tighten in 0.1.0 for multi-dataset consistency. |
| **Authentication** | | | |
| `gee_auth()` | experimental | 0.0.0.9000 | Thin wrapper over `gargle::token_fetch()`. |
| `gee_status()` | experimental | 0.0.0.9000 | Print-method output format is subject to change. |
| `gee_setup()` | experimental | 0.0.0.9000 | Interactive-only. |
| **Utilities** | | | |
| `gee_datasets()` | experimental | 0.0.0.9000 | Returns `data.table`. |
| `gee_register_dataset()` | experimental | 0.0.0.9000 | Side-effect: mutates internal environment. |
| `gee_clear_cache()` | experimental | 0.0.0.9000 | |
| **Re-exports (upstream stability applies)** | | | |
| `terra::rast()` | re-exported | 0.0.0.9000 | Stability tracks `terra`. |
| `terra::ext()` | re-exported | 0.0.0.9000 | Stability tracks `terra`. |
| `sf::st_as_sf()` | re-exported | 0.0.0.9000 | Stability tracks `sf`. |
| `sf::st_bbox()` | re-exported | 0.0.0.9000 | Stability tracks `sf`. |

Regenerate this table from the roxygen `@lifecycle` tags + `NAMESPACE` when it
goes out of date (`data-raw/regen_api_stability.R`, planned).

## Deprecation cycle

Every deprecation follows at least three releases:

1. `lifecycle::deprecate_warn("X.Y.Z", "old_fn()")` — soft warning.
2. `lifecycle::deprecate_stop("X.Y+1.0", "old_fn()")` — hard error.
3. Source removal in `X.Y+2.0` (or the next major, whichever comes first).

Each deprecation decision is recorded as an ADR under `adr/`.

## Supported versions

| Version | Status | Supported until |
|---|---|---|
| 0.0.0.9xxx dev | current development | next tagged release |
| (no tagged releases yet) | — | — |

Post-0.1.0 the support policy will be: latest minor + previous minor both
receive security and correctness patches; older versions best-effort.

## Dependency version policy

- `Imports:` version floors tested in CI (`test-coverage.yaml`).
- Floors raised only in minor+ releases; never in a patch.
- Heavy new deps require an ADR before addition (see `adr/0003-imports-budget.md`).
- At time of writing (0.0.0.9001) Imports count sits at the archetype-6a soft
  cap (10). Any new Imports dep needs explicit ADR justification.
