# List available GEE datasets

**\[experimental\]**

Returns a
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
of all datasets available in the geefetch registry, including their GEE
collection ID, domain, spatial resolution, temporal resolution, and
description.

Custom datasets registered via
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)
are included.

## Usage

``` r
gee_datasets(domain = NULL)
```

## Arguments

- domain:

  Character. Filter to a specific domain (e.g., `"Vegetation"`,
  `"Climate"`, `"Soil (AU)"`). Default `NULL` returns all.

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns:

- dataset:

  Normalised dataset ID (use with
  [`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md))

- collection:

  GEE ImageCollection ID

- domain:

  Scientific domain

- resolution:

  Spatial resolution description

- temporal:

  Temporal resolution

- description:

  Human-readable description

- date_start:

  Earliest available date (or NA for static)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)

Other utilities:
[`gee_clear_cache()`](https://aagi-aus.github.io/geefetch/reference/gee_clear_cache.md),
[`gee_external_facts()`](https://aagi-aus.github.io/geefetch/reference/gee_external_facts.md),
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)

## Examples

``` r
if (FALSE) { # interactive()
gee_datasets()
gee_datasets(domain = "Vegetation")
}
```
