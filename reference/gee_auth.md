# Authenticate with Google Earth Engine

**\[experimental\]**

Authenticates with GEE using Google OAuth via the
[gargle::gargle](https://gargle.r-lib.org/reference/gargle-package.html)
package. This is the same authentication flow used by
[googlesheets4](https://googlesheets4.tidyverse.org/),
[googledrive](https://googledrive.tidyverse.org/), and
[bigrquery](https://bigrquery.r-dbi.org/) – no Python required.

**Before calling `gee_auth()` for the first time**, complete the
one-time Google Cloud setup described in
[`vignette("geefetch")`](https://aagi-aus.github.io/geefetch/articles/geefetch.md)
under "Authentication". In short: create a GCP project under a single
Google account, register it with Earth Engine for noncommercial use,
enable the Earth Engine API on that project. Then authenticate in R
using the project **number** (not the ID string) together with the
matching email address.

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

  Character. Google account email for OAuth. Should match the account
  that owns the Google Cloud project passed as `project`. Use `NA` to
  force interactive account selection, or `""` to suppress
  auto-selection. Default uses
  [`gargle::gargle_oauth_email()`](https://gargle.r-lib.org/reference/gargle_options.html).

- path:

  Character. Path to a service account JSON key file. Mutually exclusive
  with `email`.

- project:

  Character. Google Cloud project to use as the resource and quota
  project. **Pass the 12-digit project number as a string** (e.g.
  `"123456789012"`) rather than the project ID – the number is
  unambiguous across Google accounts and avoids a common class of HTTP
  403 errors where the OAuth token's implicit quota project differs from
  the intended resource project. The Earth Engine API must be enabled on
  this project. If `NULL` (default), falls back to
  `getOption("geefetch.project")` or `"earthengine-legacy"`.

- scopes:

  Character. OAuth scopes. Default includes Earth Engine and Cloud
  Platform scopes.

- cache:

  Character. Directory for OAuth token cache. Default:
  [`gargle::gargle_oauth_cache()`](https://gargle.r-lib.org/reference/gargle_options.html).

## Value

Invisibly returns the gargle token. Called for side effects.

## Project number vs ID

Google Cloud projects have two identifiers: a string **ID** (e.g.
`geefetch-dev`) and a 12-digit **number** (e.g. `123456789012`). IDs are
not globally unique across accounts in the sense the user experiences –
the same string can be registered by different accounts and resolved
against each account's catalogue at request time, which leads to
confusing cross-project errors. Numbers are unambiguous. `geefetch`
sends both the number-as-URL-path and an `X-Goog-User-Project` header so
that Google Earth Engine bills the correct project regardless of the
OAuth token's default binding. You can find the number at
<https://console.cloud.google.com/home/dashboard?project=YOUR_ID>.

## Service accounts

For automated pipelines (CI, HPC), create a service account in Google
Cloud Console, enable the Earth Engine API, and download the JSON key.
Then authenticate with:

    gee_auth(
      project = "123456789012",
      path    = "path/to/service-account.json"
    )

## Persisting the project

To avoid typing the project number every session, set it once in your
`.Rprofile`:

    options(geefetch.project = "123456789012")

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
# Recommended form -- explicit project number + matching email.
gee_auth(
  project = "123456789012",
  email   = "me@gmail.com"
)

# Interactive OAuth (uses cached account)
gee_auth(project = "123456789012")

# Service account (CI / non-interactive)
gee_auth(project = "123456789012", path = "path/to/service-account.json")
}
```
