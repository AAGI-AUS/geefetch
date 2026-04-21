# Security policy — geefetch

## Supported versions

Pre-release development. Security patches target the latest commit on
`main`. Once tagged releases ship, the latest minor and the previous
minor are supported with security fixes; older versions are best-effort.

| Version | Supported |
|---------|-----------|
| `main` (development) | yes |
| Tagged releases < current minor | best-effort |

## Reporting a vulnerability

**Do not open a public issue.**

- Preferred: GitHub private security advisory at
  <https://github.com/AAGI-AUS/geefetch/security/advisories/new>.
- Alternate: email `max.moldovan@adelaide.edu.au` with subject
  `[SECURITY] geefetch`.

Please include:

- Affected version(s) / commit SHA.
- A reproducer (or a description if the reproducer is itself sensitive —
  e.g. involves a specific GEE project, service-account key, or cached
  response that cannot be shared publicly).
- Any known mitigations.

## Response SLA

- Acknowledgement within **72 hours**.
- Triage and severity assessment within **7 days**.
- Fix target: critical within 14 days, high within 30 days, medium in
  the next scheduled release.

## Disclosure policy

- Coordinated disclosure: reporter and maintainer agree on a public
  disclosure date.
- CVE identifier requested via GitHub Security Advisory where applicable.
- Credit recorded in `NEWS.md` and the advisory unless the reporter
  prefers anonymity.

## Scope

In scope:

- The R package as published to GitHub and R-Universe
  (`aagi-aus.r-universe.dev`), and in future to CRAN.
- Helper scripts under `inst/`, workflows under `.github/workflows/`.
- Authentication code paths (`gee_auth()`, `gee_status()`, `gee_setup()`)
  and the REST backend (`backend_rest.R`).
- Cache-handling code paths (cache-key construction, disk paths, TTL).

Out of scope:

- Vulnerabilities in third-party services (Google Earth Engine REST API,
  OAuth endpoints) — report those to Google.
- Vulnerabilities in Imports-declared dependencies (`httr2`, `gargle`,
  `sf`, `terra`, `data.table`, `cli`, `rlang`, `digest`, `lubridate`)
  — report upstream; we will coordinate pinning / minimum version bumps.
- Operational issues on Google Cloud projects owned by users (credential
  scope, project quota, billing).

## Credential handling — user-facing notes

geefetch never stores, logs, or transmits credentials itself. Authentication
state is delegated to `gargle` (the same library used by `googlesheets4`,
`bigrquery`, `googledrive`). Token caching location, rotation, and
expiry are gargle's responsibility. If you believe geefetch is mishandling
credentials, please report via the channel above.

## Supply-chain hygiene

This package follows the `/rpkg security` recipe:

- Dependabot-pinned GitHub Actions (`.github/dependabot.yml`).
- `dependency-review` on every PR (planned — see open issue tracker).
- SBOM / attestations on tagged releases (planned — see open issue tracker).
- No vendored sub-libraries; every compiled dependency is declared in
  `DESCRIPTION` and installed from CRAN / R-Universe.
