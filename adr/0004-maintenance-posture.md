# ADR 0004 — Maintenance posture

- **Status:** accepted
- **Date:** 2026-04-21
- **Deciders:** Max Moldovan

## Context

LLM-assisted development lets a two-person team ship a package surface that
historically required a five-person team. That's good for velocity but raises
the maintenance-capacity question loudly: *who reviews what, and what happens
when people disappear?*

geefetch has two maintainers (Max Moldovan, Adam H. Sparks), institutional
funding (GRDC project CUR2210-005OPX), and a published commitment to a
government-relevant user base (AAGI-AUS, Australian grains industry).
Maintenance posture is not an afterthought.

## Decision

### 1. Capacity is publicly stated

`SUPPORT.md` ships with an honest capacity block:

- Primary: Max Moldovan, ~2–4 h/wk.
- Secondary: Adam H. Sparks, ~1 h/wk.
- Bus factor: 2.

Capacity is honest, not aspirational. Users can plan around it; maintainers
are not over-committed.

### 2. Distribution is R-Universe-first

- Every merge to `main` rebuilds `aagi-aus.r-universe.dev/geefetch` within
  ~1 hour.
- CRAN submission follows once the API is stable and the test surface is
  validated against live GEE traffic (target: 0.1.0 + 4 weeks green on main).
- JOSS submission tracks the first tagged release (0.1.0). `rpkg paper joss`
  scaffolds when we're ready.

### 3. Governance surfaces are discoverable

Every piece of documentation a successor maintainer needs is at a predictable
path:

- `CITATION.cff` — how to cite.
- `CODE_OF_CONDUCT.md` — behaviour baseline.
- `CONTRIBUTING.md` — dev setup + competence matrix.
- `SECURITY.md` — vulnerability disclosure.
- `SUPPORT.md` — capacity + sunset protocol.
- `API_STABILITY.md` — per-function lifecycle.
- `COPYRIGHT` — logo carve-out for AAGI / GRDC / Curtin / UQ / Adelaide.
- `adr/` — architectural decisions.
- `.github/CODEOWNERS` — who reviews what.

### 4. Abandonment has a written protocol

Documented in `SUPPORT.md` §"Abandonment / sunset protocol":

- 6 months of no maintainer activity → AAGI-AUS org steward opens a
  `lifecycle:seeking-maintainer` issue.
- 3 further months of no volunteer → final CRAN archival release;
  `lifecycle` badges flip to `deprecated` or `superseded`.
- Repo archived; no new issues / PRs accepted.

This protects users (no surprise abandonment) and maintainers (no unbounded
obligation).

### 5. Competence matrix gates compiled-code additions

`CONTRIBUTING.md` carries a maintainer-competence matrix. **No compiled
code** (C, C++, Rust, Fortran) may land in `geefetch/src/` without a named
Secondary competent in the language and willing to review future PRs in it.

This is the load-bearing human-in-the-loop defence for LLM-assisted
contributions: a fluent reviewer of the target language must exist on the
team. No "LLM wrote it, LLM reviewed it" pipeline.

## Consequences

**Positive:**

- Users can plan: "they answer bugs within a week; they take 14 days on
  feature triage; if they disappear, the org will say so within 6 months."
- Successor maintainers have a map of where to look.
- The 2-person team doesn't accumulate unreviewed LLM-written code in an
  unfamiliar language.

**Negative:**

- Stated capacity limits may feel exposing. They protect more than they cost.
- The competence-matrix gate means we can't accept a Rust PR today even if it
  would be useful — someone fluent in Rust would have to join the team first.

## Revisit trigger

Reopen this ADR when:

- Maintainer capacity changes materially (either way).
- A third maintainer joins.
- Distribution strategy changes (e.g. CRAN becomes primary, R-Universe
  sunset).
- The abandonment protocol fires for real — we'll learn from it and refine.

## References

- `/rpkg` `recipes/31_governance.md`.
- `/rpkg` `rubrics/llm_independence.md`.
- `/rpkg` `rubrics/mandatory_uplift.md` §S5.
