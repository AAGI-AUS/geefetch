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
# From GitHub (development version, with vignettes)
remotes::install_github("max578/geefetch", subdir = "geefetch",
                        build_vignettes = TRUE)
```

## Authentication

geefetch uses the same Google OAuth flow as `googlesheets4`,
`googledrive`, and `bigrquery` via the `gargle` package.

``` r
library(geefetch)

# Interactive OAuth (opens browser)
gee_auth()

# Check your connection
gee_status()
```

    ## -- geefetch status --
    ## v Authenticated: yes
    ## i Project: "earthengine-legacy"
    ## i Backend: REST API (httr2 + gargle)
    ## i Cache dir: '~/Library/Caches/.../geefetch'
    ## i Registered datasets: 19

For non-interactive use (CI, HPC), use a service account:

``` r
gee_auth(path = "path/to/service-account.json")
```

For first-time setup,
[`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)
provides step-by-step instructions.

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
