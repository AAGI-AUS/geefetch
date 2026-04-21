# ADR 0002 — Class system

- **Status:** accepted
- **Date:** 2026-04-21
- **Deciders:** Max Moldovan

## Context

R offers several class systems: S3 (informal), S4 (formal, used by `Matrix`,
`sf` partially, Bioconductor), R6 (mutable reference), S7 (new, successor to
S3/S4, actively developed by the R consortium).

For geefetch we had to decide which system(s) to use for:

- Return values from extraction functions (raster + tabular).
- Internal dataset-metadata objects (`.GEE_META` entries).
- Handler registry types.
- Authentication state.

## Decision

**No new formal class hierarchies in geefetch.** Return types are the classes
of upstream packages (`terra::SpatRaster`, `data.table`, `sf::sfc`); internal
types are plain lists with `attr(x, "class")` where S3 dispatch is useful.

Concretely:

- `read_gee()` and all `read_*()` aliases return `terra::SpatRaster`.
- `collect_gee_data()` returns `data.table`.
- `gee_status()` returns an S3 list with class `"gee_status"` for printing,
  but with no formal accessor generics — users inspect fields directly.
- `.GEE_META` entries are plain named lists.
- No R6, no S4, no S7.

## Consequences

**Positive:**

- **Zero class-system learning curve for users.** Anyone fluent in `terra` +
  `data.table` + `sf` can use geefetch's returns without a type-system
  detour.
- **No "class bikeshedding" at PR review time.** Contributors don't debate
  whether a new type should be S3 or S7; there's no option.
- **Interop is free.** `SpatRaster` plugs into `terra::plot()`, `tidyterra`,
  `leaflet`, modelling packages. `data.table` plugs into everything.
- **Bus factor ≥ 2.** Both maintainers know the upstream class systems; no
  specialist knowledge required.

**Negative:**

- If geefetch ever grows an internal object that would legitimately benefit
  from S7 (e.g. a stateful session object across multiple requests), we'll
  have to reopen this ADR.
- Some users may expect `class(read_gee(...))` to return `"gee_result"` or
  similar. They don't get that.

## Alternatives considered

- **S7 for internal types.** Rejected: adds a toolchain dependency (`S7`
  package) and a learning curve for reviewers, for types that are internal
  and rarely dispatched on.
- **R6 for auth state.** Rejected: `.geefetch_env` (an internal environment)
  does the same job without R6's mutable-class ceremony.
- **S4 for raster outputs.** Rejected: `terra::SpatRaster` is S4 upstream;
  wrapping it in another S4 class would be pure ceremony.

## Revisit trigger

Reopen this ADR if:

- geefetch adds a session / client object with multiple stateful methods.
- Upstream `terra` or `sf` migrate to S7 (then we align).
- rOpenSci review requests a formal class for extensibility.

## References

- Hadley Wickham, "Advanced R" §Class systems.
- `rpkg` recipe 17 (S7 class system) — archetype-specific guidance; archetype
  6a defaults to S3.
