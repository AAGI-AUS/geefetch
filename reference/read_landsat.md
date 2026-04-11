# Read Landsat 9 NDVI from Google Earth Engine

Computes NDVI from Landsat 9 OLI-2 Collection 2 Level-2 surface
reflectance (LANDSAT/LC09/C02/T1_L2) on Google Earth Engine. Cloud,
shadow, and snow pixels are masked using the QA_PIXEL band.

## Usage

``` r
read_landsat(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1
)
```

## Arguments

- date:

  Character or Date. Acquisition date in `"YYYY-MM-DD"` format.

- region:

  An [sf::sf](https://r-spatial.github.io/sf/reference/sf.html),
  [`sf::st_sfc()`](https://r-spatial.github.io/sf/reference/sfc.html),
  or
  [`terra::ext()`](https://rspatial.github.io/terra/reference/ext.html)
  object defining the spatial extent. Required.

- backend:

  Character. `"rest"` (default) or `"rgee"`.

- cache:

  Logical. Use disk cache? Default `TRUE`.

- max_tries:

  Integer. Retry attempts. Default `3L`.

- initial_delay:

  Numeric. Initial retry delay in seconds. Default `1`.

## Value

A
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
SpatRaster. CRS: EPSG:4326. Values: NDVI (-1 to 1). NA where QA_PIXEL
indicates cloud, shadow, or snow.

## Data availability

2021-10-31 to present. 16-day revisit. 30 m spatial resolution.

## References

U.S. Geological Survey. Landsat 9 Collection 2 Level-2 Science Products.
[doi:10.5066/P9OGBGM6](https://doi.org/10.5066/P9OGBGM6)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
ndvi <- read_landsat(date = "2024-06-15",
                     region = terra::ext(138, 140, -36, -34))
}
```
