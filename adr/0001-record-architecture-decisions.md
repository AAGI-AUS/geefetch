# ADR 0001 — Record architecture decisions

- **Status:** accepted
- **Date:** 2026-04-21
- **Deciders:** Max Moldovan (primary maintainer)

## Context

geefetch is a two-maintainer R package with institutional funding (GRDC /
Curtin / AAGI). Decisions about class system, dependency budget, maintenance
posture, and public-API shape are load-bearing: the cost of reversing them
rises quickly as the package attracts users.

Absent explicit records, these decisions fossilise silently into code and
into the heads of current maintainers. When the package changes hands (or
when future-us forgets the reasoning), the cost is high.

## Decision

We will record all architecturally-significant decisions as Architecture
Decision Records (ADRs) under `adr/` in the repository root (intentionally
outside `geefetch/` to avoid pkgdown's `docs/` output-directory collision and
to stay out of the R package tarball).

Format: [Nygard-style ADR](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
— a short Markdown file per decision with **Context**, **Decision**,
**Consequences**, **Status**. New ADRs get the next sequential number.

## Consequences

**Positive:**

- Successor maintainers can read the reasoning, not just the code.
- Reviewers have a canonical reference when a PR conflicts with prior intent.
- Public record of "why not X" conversations that otherwise dissipate.

**Negative:**

- Low but non-zero overhead per decision.
- Requires discipline: only architecturally significant decisions go here, not
  every PR description.

## Criteria for "architecturally significant"

An ADR is warranted when a decision:

1. Affects the public API surface (signatures, return types, export count).
2. Adds or removes an `Imports:` or `Depends:` dependency.
3. Changes the archetype classification or the fundamental integration pattern
   (e.g. REST-first vs rgee-first).
4. Touches governance posture (maintenance capacity, bus factor, succession).
5. Any decision someone in 12 months might ask "why did we do X?" about.

Routine refactors, bug fixes, and documentation edits are NOT ADRs.

## Initial ADRs

- `0001-record-architecture-decisions.md` (this document).
- `0002-class-system.md` — why S3, not S7.
- `0003-imports-budget.md` — the 10-dep ceiling and how we defend it.
- `0004-maintenance-posture.md` — capacity, succession, abandonment protocol.

## References

- Michael Nygard, "Documenting Architecture Decisions" (2011).
- [`adr-tools`](https://github.com/npryce/adr-tools) — not a dependency; the
  format is deliberately light-weight.
- `rpkg` recipe 31 (governance).
