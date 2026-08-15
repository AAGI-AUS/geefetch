# External-fact provenance registry

**\[experimental\]**

Enumerates every fact `geefetch` asserts about Google Earth Engine –
each dataset's collection (asset) ID, scale factor, offset, band set,
and start date – alongside the external authority that owns the fact and
the date the fact was last diffed against that authority. A fact whose
`verified_on` is `NA` is reported as `[unverified]`: a value the package
asserts but has **not** grounded against an independent oracle, and
which must be treated as a hypothesis rather than a fact.

The fact values are read live from the internal registry, so this table
can never drift from the code it documents. Grounding is established by
the independent-oracle tests (catalogue diff against the public GEE
STAC, and an optional live-contract check); see the package tests.

## Usage

``` r
gee_external_facts(grounded_only = FALSE)
```

## Arguments

- grounded_only:

  Logical. If `TRUE`, return only facts with a non-`NA` `verified_on`.
  Default `FALSE` (return all, including `[unverified]`).

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html),
one row per externally-grounded fact, with columns:

- dataset:

  Normalised dataset ID.

- fact_id:

  `<dataset>.<fact>` identifier.

- kind:

  Fact kind: `locator`, `enum`, `scale`, or `bound`.

- value:

  The value the package asserts (read live from the registry).

- source:

  The authority that owns the fact (a GEE STAC catalogue URL).

- verified_on:

  ISO date last diffed against `source`, or `NA`.

- grounding:

  `"grounded"` or `"[unverified]"`.

- oracle_types:

  Which oracle(s) ground (or would ground) the fact.

- reverify_by:

  `"stable"` or `"volatile"`.

## See also

[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)

Other utilities:
[`gee_clear_cache()`](https://aagi-aus.github.io/geefetch/reference/gee_clear_cache.md),
[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md),
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)

## Examples

``` r
if (FALSE) { # interactive()
gee_external_facts()
gee_external_facts(grounded_only = TRUE)
}
```
