# Guided first-time setup for GEE access

**\[experimental\]**

Interactive setup wizard that checks prerequisites, guides the user
through Google Earth Engine registration and authentication, and
verifies the connection.

## Usage

``` r
gee_setup()
```

## Value

`NULL`, invisibly. Called for side effects (prints instructions and
optionally initiates authentication).

## See also

[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md),
[`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)

Other authentication:
[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md),
[`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)

## Examples

``` r
if (FALSE) { # interactive()
gee_setup()
}
```
