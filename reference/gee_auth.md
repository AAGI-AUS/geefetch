# Authenticate with Google Earth Engine

Authenticates with GEE using Google OAuth via the
[gargle::gargle](https://gargle.r-lib.org/reference/gargle-package.html)
package. This is the same authentication flow used by
[googlesheets4](https://googlesheets4.tidyverse.org/),
[googledrive](https://googledrive.tidyverse.org/), and
[bigrquery](https://bigrquery.r-dbi.org/) — no Python required.

For non-interactive use (CI, servers), use a service account JSON key
file via `gee_auth(path = "service-account.json")`.

## Usage

``` r
gee_auth(
  email = gargle::gargle_oauth_email(),
  path = NULL,
  project = NULL,
  scopes = .GEE_SCOPES,
  cache = gargle::gargle_oauth_cache()
)
```

## Arguments

- email:

  Character. Google account email for OAuth. Use `NA` to force
  interactive account selection, or `""` to suppress auto-selection.
  Default uses
  [`gargle::gargle_oauth_email()`](https://gargle.r-lib.org/reference/gargle_options.html).

- path:

  Character. Path to a service account JSON key file. Mutually exclusive
  with `email`.

- project:

  Character. Google Cloud project ID with Earth Engine API enabled.
  Default `"earthengine-legacy"` (the public project). Set to your own
  project for higher quotas.

- scopes:

  Character. OAuth scopes. Default includes Earth Engine and Cloud
  Platform scopes.

- cache:

  Character. Directory for OAuth token cache. Default:
  [`gargle::gargle_oauth_cache()`](https://gargle.r-lib.org/reference/gargle_options.html).

## Value

Invisibly returns the gargle token. Called for side effects.

## Service accounts

For automated pipelines (CI, HPC), create a service account in Google
Cloud Console, enable the Earth Engine API, and download the JSON key.
Then authenticate with:

    gee_auth(path = "path/to/service-account.json")

## See also

[`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)
to check authentication state,
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)
for guided first-time setup.

Other authentication:
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md),
[`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)

## Examples

``` r
if (FALSE) { # interactive()
# Interactive OAuth (opens browser)
gee_auth()

# Specify account
gee_auth(email = "me@gmail.com")

# Service account (CI / non-interactive)
gee_auth(path = "path/to/service-account.json")

# Use your own GCP project for higher quotas
gee_auth(email = "me@gmail.com", project = "my-gee-project")
}
```
