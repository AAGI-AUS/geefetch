# geefetch

<!-- badges: start -->
[![R-CMD-check](https://github.com/AAGI-AUS/geefetch/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/AAGI-AUS/geefetch/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/AAGI-AUS/geefetch/graph/badge.svg)](https://codecov.io/gh/AAGI-AUS/geefetch)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**Google Earth Engine Fast Easy Terrestrial Covariate Harvester**

geefetch provides a unified R interface for extracting spatio-temporal
environmental covariates from [Google Earth Engine](https://earthengine.google.com/).

**No Python required.** Unlike `rgee`, geefetch accesses GEE directly via
the REST API using `httr2` and `gargle`. Install it like any normal R
package and authenticate with the same Google OAuth flow as `googlesheets4`.

**Documentation: <https://aagi-aus.github.io/geefetch/>**

## Features

| Feature | Detail |
|---|---|
| **Python-free** | Uses GEE REST API directly -- no reticulate, no conda |
| **19+ built-in datasets** | Vegetation, climate, soil, topography, bioclimatic |
| **One-function extraction** | `read_gee()` dispatcher + named convenience aliases |
| **Batch extraction** | `collect_gee_data()` -- multi-location x multi-date x multi-dataset |
| **Automatic caching** | Disk-backed, hash-keyed, TTL-aware |
| **User-extensible** | Register any GEE collection with `gee_register_dataset()` |
| **nert-compatible** | Same output types (`terra::rast()`, `data.table`), same naming patterns |

## Installation

``` r
# Install from GitHub (with vignettes)
remotes::install_github("AAGI-AUS/geefetch", subdir = "geefetch",
                        build_vignettes = TRUE)
```

## Quick start

``` r
library(geefetch)

# Authenticate (opens browser -- same as googlesheets4)
gee_auth()

# Extract MODIS NDVI for a region
ndvi <- read_modis_ndvi(
  date   = "2024-06-15",
  region = terra::ext(138, 140, -36, -34)
)
terra::plot(ndvi)

# Batch extraction: multiple datasets, multiple locations
sites <- data.frame(lon = c(138.6, 149.1), lat = c(-34.9, -35.3))

covariates <- collect_gee_data(
  xy         = sites,
  date_range = c("2024-01-01", "2024-12-31"),
  datasets   = c("modis_ndvi", "era5_temp", "chirps_precip", "srtm_elevation")
)
```

## Built-in datasets

| Dataset | Alias | Domain | Resolution | Temporal |
|---|---|---|---|---|
| MODIS Terra NDVI | `read_modis_ndvi()` | Vegetation | 1 km | 16-day |
| MODIS Terra LST | `read_modis_lst()` | Temperature | 1 km | 8-day |
| ERA5-Land temperature | `read_era5()` | Climate | 11 km | Daily |
| ERA5-Land precipitation | `read_era5()` | Climate | 11 km | Daily |
| CHIRPS precipitation | `read_chirps()` | Precipitation | 5.5 km | Daily |
| SRTM elevation | `read_srtm()` | Topography | 30 m | Static |
| SLGA soil (7 attributes) | `read_slga()` | Soil (AU) | 90 m | Static |
| Sentinel-2 NDVI | `read_sentinel2()` | Vegetation | 10 m | 5-day |
| Landsat 9 NDVI | `read_landsat()` | Vegetation | 30 m | 16-day |
| WorldClim bioclim | `read_worldclim()` | Bioclimatic | 1 km | Static |
| OpenLandMap soil | `read_gee()` | Soil (Global) | 250 m | Static |

Browse all datasets: `gee_datasets()`

## Documentation

Full documentation and tutorials are available at
**<https://aagi-aus.github.io/geefetch/>**

- [Getting started](https://aagi-aus.github.io/geefetch/articles/geefetch.html)
- [Batch extraction workflows](https://aagi-aus.github.io/geefetch/articles/collect_gee_data.html)
- [Adding custom GEE collections](https://aagi-aus.github.io/geefetch/articles/custom_datasets.html)

## Authors

- **Max Moldovan** (maintainer) -- Adelaide University
  ([ORCID](https://orcid.org/0000-0001-9680-8474))
- **Adam H. Sparks** -- DPIRD / Curtin University
  ([ORCID](https://orcid.org/0000-0002-0061-8359))

## Licence

MIT
