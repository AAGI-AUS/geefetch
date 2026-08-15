# Clear the geefetch disk cache

**\[experimental\]**

Removes cached extraction results from disk. Optionally filter by age to
keep recent results.

## Usage

``` r
gee_clear_cache(older_than = NULL)
```

## Arguments

- older_than:

  Numeric. Only remove cache files older than this many days. Default
  `NULL` removes all files.

## Value

Invisibly returns the number of cache files removed.

## See also

[`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)
to check cache size.

Other utilities:
[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md),
[`gee_external_facts()`](https://aagi-aus.github.io/geefetch/reference/gee_external_facts.md),
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)

## Examples

``` r
if (FALSE) { # interactive()
# Clear everything
gee_clear_cache()

# Clear only files older than 7 days
gee_clear_cache(older_than = 7)
}
```
