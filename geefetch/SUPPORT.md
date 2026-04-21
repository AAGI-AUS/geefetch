# geefetch support

## Getting help

Start here before opening an issue:

1. Read the **Getting Started** vignette: `vignette("geefetch")`.
2. Browse the pkgdown site: <https://aagi-aus.github.io/geefetch/>.
3. Search the [open and closed issues](https://github.com/AAGI-AUS/geefetch/issues).
4. Use [GitHub Discussions](https://github.com/AAGI-AUS/geefetch/discussions) for
   usage questions and ideas; reserve Issues for bugs and concrete feature
   requests.

Authentication and setup troubleshooting is covered in `?gee_setup` and in the
**Getting Started** vignette.

## Maintenance capacity

**Please read this before filing feature requests, opening large PRs, or
assuming a response time.** Honest capacity disclosure protects both users and
maintainers.

### Time budget

| Maintainer | Role | Capacity |
|---|---|---|
| Max Moldovan (Adelaide University) | Primary / `cre` | ~2–4 hours per week |
| Adam H. Sparks (Curtin University) | Secondary / review | ~1 hour per week |

Capacity can drop temporarily during teaching, fieldwork, conference travel, or
grant-writing cycles. During those periods, issue triage may lag by up to
10–14 days.

### Response expectations

- **Bugs with a reprex:** acknowledged within 7 days. Fix cadence depends on
  severity — see [SECURITY.md](SECURITY.md) for the security-specific SLA.
- **Feature requests:** triaged within 14 days. Not every request is in scope
  — see [API_STABILITY.md](API_STABILITY.md) and [DESCRIPTION](DESCRIPTION)
  for scope boundaries. Low-effort, in-scope asks land fastest.
- **Pull requests:** initial review within 14 days. Complex PRs may take
  multiple review rounds.
- **Discussions:** best-effort, no SLA.

### Bus factor

**Bus factor: 2.** Both maintainers can triage, review, and release. The
competence-matrix table in [CONTRIBUTING.md](CONTRIBUTING.md) documents who
holds domain knowledge for each subsystem.

### Abandonment / sunset protocol

If geefetch receives no maintainer activity for **6 months** (no commits,
no issue responses, no release):

1. The AAGI-AUS org steward (GitHub `@AAGI-AUS` owners) opens a
   `lifecycle:seeking-maintainer` issue and notifies the mailing list.
2. If no maintainer steps forward within **3 months**, the `lifecycle` badge
   on every exported function flips to `superseded` (if a replacement exists)
   or `deprecated` (if not), and a final CRAN archival release ships.
3. The GitHub repo is archived (read-only). Historical source remains
   available; no new issues or PRs are accepted.

This protocol is documented here so it isn't ambiguous when it's needed.

### What we don't support

- **Non-GEE data sources.** This is deliberately scoped to Google Earth Engine.
  For Australian sensor-network data, use
  [`nert`](https://github.com/AAGI-AUS/nert). For SoilGrids, WorldClim direct
  access, GBIF, etc., use the specialised upstream packages.
- **Server-side GEE computation.** geefetch extracts; it does not orchestrate
  server-side mosaicing, classification, or band algebra beyond the scale /
  offset / filter primitives needed for extraction. Use
  [`rgee`](https://r-spatial.github.io/rgee/) for complex server-side work.
- **Visualisation.** Use `terra::plot()`, `ggplot2` + `tidyterra`, or
  `leaflet`.
- **Modelling.** Use `nlme`, `mgcv`, `ranger`, `brms`, etc. geefetch stops at
  the `data.table` / `SpatRaster` output.

## Commercial support

Consulting engagements are case-by-case via Max's consulting practice. For
organisational-scale deployments, data-pipeline integration, or custom GEE
workflow development, open a discussion thread and we'll scope it.
