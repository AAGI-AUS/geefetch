# Check GEE connection status

Reports the current state of the GEE connection: authentication status,
active backend, project ID, cache directory, and cache size.

## Usage

``` r
gee_status()
```

## Value

A list (invisibly) with components:

- authenticated:

  Logical. Is a valid token available?

- project:

  Character. Active GCP project ID.

- rgee_available:

  Logical. Is rgee installed?

- cache_dir:

  Character. Path to disk cache directory.

- cache_size:

  Numeric. Cache size in MB.

- n_datasets:

  Integer. Number of registered datasets.

## See also

[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md),
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)

Other authentication:
[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md),
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)

## Examples

``` r
if (FALSE) { # interactive()
gee_status()
}
```
