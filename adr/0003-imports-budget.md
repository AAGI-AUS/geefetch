# ADR 0003 — Imports budget

- **Status:** accepted
- **Date:** 2026-04-21
- **Deciders:** Max Moldovan

## Context

The `/rpkg` v0.4 api-ergonomics rubric puts a soft cap of **10 Imports** on
archetype-6 (wrapper) packages. Every dependency a package takes on imposes
downstream install-time cost, CRAN-release-coupling cost, and
attack-surface cost.

At the time this ADR is written, geefetch's Imports stand at **11** (10
non-trivial + `lifecycle`):

```
cli, data.table, digest, gargle (>= 1.5.0), httr2 (>= 1.0.0),
lifecycle, lubridate, rlang (>= 1.1.0), sf, terra, utils
```

**`lifecycle` is treated as a doc-only metadata dep** — it is only invoked
from roxygen comments (`lifecycle::badge(...)` at Rd render time) and does
not count against the non-trivial cap. Without it the per-function
lifecycle badges surfaced in `API_STABILITY.md` cannot render.

The non-trivial count is **10**. We are at the soft cap. Every future
non-metadata addition requires justification.

## Decision

**geefetch operates to an Imports ceiling of 10 packages** (excluding `utils`,
`methods`, and `R` itself per CRAN convention — effectively the published cap
of "10 non-trivial external deps").

New Imports additions require:

1. **An ADR** explaining the value and rejecting plausible alternatives.
2. **≥ 5 distinct call-sites** in `R/` using the package (guards against
   Import for a one-liner).
3. **No equivalent functionality** in an already-imported package.

Packages used only in tests or vignettes go to `Suggests:`, gated by
`rlang::is_installed()` or `requireNamespace()` at the call site.

## Consequences

**Positive:**

- Small dependency footprint → fast install → fewer CRAN-release surprises.
- Easier to reason about the supply chain (fewer transitive deps to audit).
- Encourages use of already-present tools instead of reaching for new ones
  (e.g. use `lubridate::ceiling_date()` we already have, not `clock::`).

**Negative:**

- Occasionally we write 5 lines of code that a new dep would reduce to 1.
  That trade-off is deliberate.
- If a Really Good new package appears in the ecosystem (e.g. a successor to
  `data.table`), we might be slow to adopt.

## Per-Import justification (snapshot 0.0.0.9001)

| Import | Justification | Call-site count |
|---|---|---|
| `cli` | Structured user messaging; `{.fn}` / `{.path}` / `{.val}` inline styling | 108+ |
| `data.table` | Primary return type for `collect_gee_data()`; `rbindlist` for feature response parsing | Many |
| `digest` | SHA-256 cache-key construction | 2 |
| `gargle` | Google OAuth / service-account token lifecycle | Multiple |
| `httr2` (>= 1.0.0) | REST backend HTTP client with built-in retry + JSON handling | Multiple |
| `lubridate` | `ceiling_date()` for monthly date-window expansion | 2 |
| `rlang` (>= 1.1.0) | `arg_match()`, `is_installed()`, `check_required()`, `%\|\|%` | Many |
| `sf` | Region validation, `st_bbox()`, GeoJSON interop | Multiple |
| `terra` | Primary return type for `read_*()` (SpatRaster) | Multiple |
| `utils` | `packageVersion()` | 1 (CRAN-standard Import) |

## Rejected additions

### `jsonlite`

Removed from Imports in commit `e1fc874`. Previously listed but never called
in `R/` — all JSON round-trips are mediated by `httr2::req_body_json()` /
`httr2::resp_body_json()` (which use `jsonlite` as a transitive dep but
that's httr2's concern, not ours).

### `yyjsonr`

Not added. The `/rpkg` archetype-6a overlay suggests `yyjsonr` over
`jsonlite` for JSON-heavy packages. geefetch is not JSON-heavy at the R
level — all parsing is inside `httr2` — so a direct `yyjsonr` Import would
be dead weight.

### `checkmate`

Not added. `rlang::check_required()` + `rlang::arg_match()` cover the input
validation surface geefetch needs. `checkmate` adds value for packages with
many numeric-parameter constraints; geefetch's parameter surface is small.

### `pingr` / `curl` / `httr`

Not added. `httr2` is the HTTP layer; transitive `curl` via `httr2` handles
low-level needs.

## Revisit trigger

Reopen this ADR when:

- We want to add a 10th non-trivial Import.
- An existing Import becomes unused (demote to Suggests or drop).
- R core absorbs functionality from an existing Import (e.g. `lubridate`
  helpers landing in base).

## References

- `/rpkg` `rubrics/api_ergonomics.md` §Imports count.
- `/rpkg` `recipes/02_archetype_taxonomy.md` §6.
