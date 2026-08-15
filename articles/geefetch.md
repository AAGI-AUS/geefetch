# Getting Started with geefetch

## Overview

**geefetch** provides a unified R interface for extracting environmental
covariates from Google Earth Engine (GEE). Unlike other GEE R packages,
geefetch works **without Python** — it uses the GEE REST API directly
via `httr2` and `gargle`.

Key features:

- **No Python required** — installs like any normal R package
- **19+ built-in datasets** — vegetation, climate, soil, topography
- **Single-function extraction** —
  [`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
  dispatcher + convenience aliases
- **Batch extraction** —
  [`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
  for multi-location, multi-date, multi-dataset
- **Automatic caching** — repeated queries are served from disk
- **User-extensible** — register any GEE collection with
  [`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)

## Installation

``` r
# From R-Universe (binaries, updated ~1 h after merge to main):
options(repos = c(
  "aagi-aus" = "https://aagi-aus.r-universe.dev",
  CRAN       = "https://cran.r-project.org"
))
install.packages("geefetch")

# Development version (latest commit on main):
pak::pak("AAGI-AUS/geefetch", subdir = "geefetch")
```

## Authentication

**Read this section fully before running
[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md).**
Skipping ahead is the fastest way to spend an afternoon debugging HTTP
403s.

Authentication to Google Earth Engine has two independent concepts that
`geefetch` exposes together:

| Concept              | What it is                                                         | Where it lives                                                                                                                     |
|----------------------|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| **Identity**         | Which Google account you’re signing in as                          | OAuth token                                                                                                                        |
| **Resource project** | Which Google Cloud project owns your EE calls, quotas, and billing | `project =` argument to [`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md) and `X-Goog-User-Project` header |

If the identity is signed into account A but the resource project was
created under account B, you’ll get HTTP 403. The rest of this section
is about making both match.

### Step 1 — Create a Google Cloud project and register it with Earth Engine

You only do this once, before you ever touch R.

1.  **Choose one Google account.** The rest of this setup — the Cloud
    project, the EE registration, the OAuth consent — must all happen
    under the *same* Google account. Using your institutional account
    (`*.edu.au`, `*.gov`, etc.) is typical for academic / research work.
    A personal Gmail account works too. Decide now and stick with it.

2.  **Create a dedicated Google Cloud project** at
    <https://console.cloud.google.com/projectcreate>. Give it a
    memorable name (e.g. `my-geefetch-dev`). Google will assign a short
    **Project ID** (the string you type, e.g. `my-geefetch-dev`) and a
    long **Project number** (a 12-digit integer, e.g. `123456789012`).
    Copy both. You’ll use the **project number** in R — it’s unambiguous
    across accounts.

3.  **Register the project for Earth Engine noncommercial use** at
    <https://code.earthengine.google.com/register>. Choose *Academic* or
    *Research*, select your new project from the dropdown, fill in the
    institution details, submit. Academic approval is usually instant.

4.  **Enable the Earth Engine API** on the project at
    <https://console.cloud.google.com/apis/library/earthengine.googleapis.com>
    — make sure the project picker top-left shows your project, then
    click **Enable**.

5.  **Verify** at <https://console.cloud.google.com/apis/dashboard> that
    “Earth Engine API” appears in the enabled APIs list for your
    project.

### Step 2 — Authenticate in R

Use the **project number**, not the project ID string. This is the
single most common cause of the 403 “Earth Engine API has not been used”
error — passing the ID can silently resolve to a different project
number under a different identity.

``` r
library(geefetch)

gee_auth(
  project = "123456789012",              # <-- YOUR project number as a string
  email   = "max.moldovan@gmail.com"     # <-- the exact Google account
)
```

A browser window will open for Google OAuth (same flow as
`googlesheets4`). Sign in as the account matching `email`, grant consent
for Earth Engine and Cloud Platform scopes, close the tab.

### Step 3 — Verify

``` r
gee_status()
```

    ## -- geefetch status --
    ## v Authenticated: yes
    ## i Project: "123456789012"
    ## i Backend: REST API (httr2 + gargle)
    ## i Cache dir: '~/Library/Caches/.../geefetch'
    ## i Registered datasets: 19

The `Project:` line must show your project **number**. If it shows an ID
string like `"earthengine-legacy"` or a different number, stop and
re-run
[`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md)
with the correct arguments.

### Step 4 — Persist across sessions

Add to your `.Rprofile` (or the top of each analysis script) so you
don’t need to re-type the project number:

``` r
options(geefetch.project = "123456789012")
# Then gee_auth() picks it up without explicit project arg.
```

### Non-interactive authentication

For CI, HPC, or any unattended context, use a service-account key file.
Create the key on the same Cloud project used above
(<https://console.cloud.google.com/iam-admin/serviceaccounts>), grant it
the **Earth Engine Resource Writer** role, download the JSON, then:

``` r
gee_auth(
  project = "123456789012",
  path    = "path/to/service-account.json"
)
```

Store the key file outside your repository. Never commit it.

### Troubleshooting — HTTP 403 decision tree

If
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md)
or any `read_*()` call returns a 403 after authentication appeared to
succeed, the error message contains a project number. Match that number
against what you expect:

| Error’s project number   | Meaning                                                                   | Fix                                                                                                                                                                                                                                    |
|--------------------------|---------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Matches your `project =` | Earth Engine API not actually enabled, or registration not yet propagated | Re-verify Step 1 items 3 + 4; wait 2-3 minutes and retry                                                                                                                                                                               |
| **Different** number     | OAuth token’s quota project disagrees with your resource project          | Restart R; wipe gargle’s token cache (`unlink(list.files(gargle::gargle_oauth_cache(), full.names = TRUE))`); re-run [`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md) with the project **number**, not the ID |

If neither helps,
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)
prints the full check-list and links to the three Google Cloud Console
pages involved.

## Your first extraction

Extract MODIS NDVI for a region in South Australia:

``` r
library(terra)

# Define a region of interest
aoi <- ext(138, 140, -36, -34)

# Extract NDVI for a specific date
ndvi <- read_modis_ndvi(date = "2024-06-15", region = aoi)

# Plot the result
plot(ndvi, main = "MODIS NDVI — 15 June 2024")
```

The result is a standard
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
— you can use all `terra` functions for analysis, cropping, masking, and
export.

## Point extraction

To extract values at specific coordinates, use
[`terra::extract()`](https://rspatial.github.io/terra/reference/extract.html):

``` r
# Define some sites
sites <- data.frame(
  lon = c(138.6, 139.5, 140.2),
  lat = c(-34.9, -35.5, -34.2)
)

# Convert to spatial points
pts <- vect(sites, geom = c("lon", "lat"), crs = "EPSG:4326")

# Extract NDVI at the sites
values <- extract(ndvi, pts)
print(values)
```

    ##   ID      NDVI
    ## 1  1 0.3245
    ## 2  2 0.4512
    ## 3  3 0.2891

## Using the dispatcher

All convenience functions
([`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
etc.) are thin wrappers around the central
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
dispatcher. You can use either form:

``` r
# These are equivalent:
ndvi <- read_modis_ndvi(date = "2024-06-15", region = aoi)
ndvi <- read_gee("MODIS_NDVI", date = "2024-06-15", region = aoi)
ndvi <- read_gee("NDVI", date = "2024-06-15", region = aoi)  # alias
```

## Browsing available datasets

``` r
gee_datasets()
```

    ##            dataset                          collection       domain resolution temporal
    ##  1:     modis_ndvi                  MODIS/061/MOD13A2   Vegetation     1000m    16day
    ##  2:      modis_lst                  MODIS/061/MOD11A2  Temperature     1000m     8day
    ##  3:      era5_temp       ECMWF/ERA5_LAND/DAILY_AGGR      Climate    11132m    daily
    ##  ...
    ## 19: openlandmap_ph  OpenLandMap/SOL/SOL_PH-H2O_...  Soil (Global)      250m   static

## Caching

geefetch automatically caches extraction results to disk. Repeated
identical queries are served instantly:

``` r
# First call: hits GEE REST API (~2-5 seconds)
elev <- read_srtm(region = aoi)

# Second call: served from disk cache (< 10 ms)
elev <- read_srtm(region = aoi)

# Check cache size
gee_status()

# Clear cache if needed
gee_clear_cache()
```

## Next steps

- See
  [`vignette("collect_gee_data")`](https://aagi-aus.github.io/geefetch/articles/collect_gee_data.md)
  for batch extraction across multiple locations, dates, and datasets
- See
  [`vignette("custom_datasets")`](https://aagi-aus.github.io/geefetch/articles/custom_datasets.md)
  for registering your own GEE collections
- See
  [`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
  for the full list of supported datasets
