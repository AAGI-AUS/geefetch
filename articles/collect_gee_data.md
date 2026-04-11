# Batch Environmental Covariate Extraction

## Overview

[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
is the primary function for building environmental covariate tables. It
extracts values from multiple GEE datasets at one or more point
locations across a date range, returning a single `data.table` ready for
modelling.

## Single location, multiple datasets

``` r
library(geefetch)
gee_auth()

dt <- collect_gee_data(
  lon = 138.6, lat = -34.9,
  date_range = c("2024-01-01", "2024-03-31"),
  datasets = c("modis_ndvi", "era5_temp", "chirps_precip", "srtm_elevation")
)

print(dt)
```

    ##    point_id   lon   lat       date modis_ndvi era5_temp chirps_precip srtm_elevation
    ## 1:        1 138.6 -34.9 2024-01-01     0.3245     28.4          0.0             48
    ## 2:        1 138.6 -34.9 2024-01-02     0.3245     30.1          0.2             48
    ## 3:        1 138.6 -34.9 2024-01-03     0.3245     27.8          5.4             48
    ## ...

**Key observations:**

- `modis_ndvi` values repeat within a 16-day composite window (same
  image)
- `era5_temp` and `chirps_precip` change daily
- `srtm_elevation` is static — the value is replicated across all dates

## Multiple locations

Pass a data.frame, matrix, or `sf` object:

``` r
sites <- data.frame(
  lon = c(138.6, 149.1, 153.0),
  lat = c(-34.9, -35.3, -27.5),
  name = c("Adelaide", "Canberra", "Brisbane")
)

dt <- collect_gee_data(
  xy = sites,
  date_range = c("2024-01-01", "2024-01-31"),
  datasets = c("modis_ndvi", "era5_temp")
)

# 3 locations x 31 dates = 93 rows
nrow(dt)
## [1] 93
```

You can also pass an `sf` POINT object — coordinates are extracted
automatically (transformed to WGS84 if needed):

``` r
library(sf)
pts_sf <- st_as_sf(sites, coords = c("lon", "lat"), crs = 4326)
dt <- collect_gee_data(
  xy = pts_sf,
  date_range = c("2024-01-01", "2024-01-31"),
  datasets = c("modis_ndvi", "era5_temp")
)
```

## Using the bundled example sites

geefetch ships with 8 Australian locations for testing:

``` r
sites_file <- system.file("extdata", "example_sites.csv", package = "geefetch")
sites <- read.csv(sites_file)
head(sites)
```

    ##   site_id     lon     lat       name
    ## 1       1 138.636 -34.929   Adelaide
    ## 2       2 149.130 -35.281   Canberra
    ## 3       3 153.025 -27.470   Brisbane
    ## 4       4 115.861 -31.951      Perth

## Column naming

Each dataset produces a column named after its normalised ID:

| Dataset          | Column name      |
|------------------|------------------|
| `modis_ndvi`     | `modis_ndvi`     |
| `era5_temp`      | `era5_temp`      |
| `srtm_elevation` | `srtm_elevation` |

Aliases (`"NDVI"`, `"SRTM"`, etc.) are resolved to normalised IDs before
extraction, so column names are always consistent.

## Handling failures

If extraction fails for a particular dataset-date-location combination
(e.g., no satellite overpass, ocean point), the value is set to `NA` and
a warning is emitted. Execution continues for remaining datasets.

Use `na.rm = TRUE` to remove rows where **all** dataset columns are
`NA`:

``` r
dt <- collect_gee_data(
  lon = 138.6, lat = -34.9,
  date_range = c("2024-01-01", "2024-01-10"),
  datasets = c("modis_ndvi", "era5_temp"),
  na.rm = TRUE
)
```

## Performance tips

1.  **Use caching** (enabled by default). Repeated identical calls are
    served from disk in milliseconds.

2.  **Narrow your date range.** Time-series datasets require one API
    call per date per location. 365 days x 10 locations x 3 datasets =
    10,950 calls.

3.  **Use coarse-resolution datasets when possible.** ERA5 (11 km) and
    MODIS (1 km) are much faster to extract than Sentinel-2 (10 m).

4.  **Combine static and dynamic datasets.** Static datasets (SRTM,
    SLGA, WorldClim, OpenLandMap) are extracted once per location, not
    per date.

## Combining with nert

If you use `nert` for TERN data and `geefetch` for GEE data, the outputs
are directly compatible — both return `data.table` with the same
coordinate/date structure:

``` r
library(nert)
library(geefetch)

# TERN data (Australian soil moisture)
tern_dt <- collect_tern_data(
  lon = 138.6, lat = -34.9,
  date_range = c("2024-01-01", "2024-01-31"),
  datasets = "SMIPS"
)

# GEE data (global climate)
gee_dt <- collect_gee_data(
  lon = 138.6, lat = -34.9,
  date_range = c("2024-01-01", "2024-01-31"),
  datasets = c("era5_temp", "chirps_precip")
)

# Merge on date
combined <- merge(tern_dt, gee_dt, by = "date")
```
