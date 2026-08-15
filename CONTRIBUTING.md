# Contributing to geefetch

Thanks for your interest in geefetch. This document is the 30-second
on-ramp.

## Dev setup

``` r
# 1. Fork and clone AAGI-AUS/geefetch
# 2. Open the subdir package (DESCRIPTION lives at geefetch/DESCRIPTION)
setwd("geefetch")

# 3. Install dev dependencies
pak::local_install_dev_deps()

# 4. Load the package
devtools::load_all()

# 5. Run the full check
devtools::check()
```

## Running the tests

``` r
devtools::test()                                     # all tests (parallel, testthat edition 3)
devtools::test_active_file()                         # just the test file currently open
devtools::test(filter = "backend_rest-http")         # just the httptest2 suite
```

All HTTP tests replay cassettes from
`tests/testthat/computeFeatures-*/`. They skip gracefully when a
cassette directory is missing. Maintainers who recapture cassettes: see
`tests/testthat/README.md`.

## Lint and format

``` r
lintr::lint_package()
# Formatter: 'air' (post-styler). Either:
system("air format .")
# or install the pre-commit hook (see .pre-commit-config.yaml).
```

## Opening a PR

- Branch naming: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`,
  `refactor/<topic>`.
- Commits: [Conventional Commits](https://www.conventionalcommits.org/).
- Expect CI to run: `R-CMD-check` (6-row matrix incl. macos-14 ARM),
  `test-coverage`, `lint`, `pkgdown`, `dependency-review`.
- Update `NEWS.md` for any user-visible change.
- Make sure `devtools::document()` was run if you touched roxygen.
- Run `air format .` (or let the pre-commit hook do it).

## Reporting a bug

Open an issue using the **Bug report** template. Include:

- A minimal reproducer via `reprex::reprex()`.
- [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) /
  [`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html).
- The expected vs actual behaviour.

## Security

Please **do not** open a public issue for security problems. See
[`SECURITY.md`](https://aagi-aus.github.io/geefetch/SECURITY.md) for the
private-disclosure channel.

## Code of Conduct

By participating you agree to abide by the [Contributor
Covenant](https://aagi-aus.github.io/geefetch/CODE_OF_CONDUCT.md).

## Maintainer competence matrix

This section exists because LLM-assisted development makes it easy to
ship code that nobody on the team is qualified to review. Every language
or framework touched by geefetch has a named Primary (and where
warranted, a Secondary for bus-factor resilience).

| Area                                 | Primary      | Secondary      |
|--------------------------------------|--------------|----------------|
| R package structure, CRAN readiness  | Max Moldovan | Adam H. Sparks |
| `httr2` REST backend + `gargle` auth | Max Moldovan | —              |
| `terra` / `sf` spatial handling      | Max Moldovan | Adam H. Sparks |
| `data.table` batch extraction        | Max Moldovan | Adam H. Sparks |
| CI / GitHub Actions                  | Max Moldovan | Adam H. Sparks |
| Documentation, vignettes, pkgdown    | Max Moldovan | Adam H. Sparks |

**No compiled code in geefetch.** If a contribution adds C++, Rust, or
other compiled sources, a Secondary competent in that language must be
added to the matrix before the PR can merge (per
`rubrics/llm_independence.md`).

## Maintainers

Primary: Max Moldovan (`max.moldovan@adelaide.edu.au`,
[ORCID](https://orcid.org/0000-0001-9680-8474)). Secondary: Adam H.
Sparks (`adam.sparks@curtin.edu.au`,
[ORCID](https://orcid.org/0000-0002-0061-8359)).

See
[`.github/CODEOWNERS`](https://aagi-aus.github.io/geefetch/.github/CODEOWNERS)
for area-specific reviewers.
