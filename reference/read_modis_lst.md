# Read MODIS Terra Land Surface Temperature from Google Earth Engine

Reads MODIS/061/MOD11A2 (Terra Land Surface Temperature/Emissivity 8-Day
L3 1km) from Google Earth Engine. Returns a
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
SpatRaster with QA-masked daytime LST values in Kelvin.

## Usage

``` r
read_modis_lst(
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
SpatRaster. CRS: EPSG:4326. Values: LST in Kelvin. NA where QA indicates
cloud or poor quality.

## Data availability

2000-02-24 to present. 8-day composites. 1 km spatial resolution.

## QA masking

Pixels where QC_Day bits 0-1 are not 00 (good quality) are masked to NA.

## References

Wan, Z., Hook, S. & Hulley, G. (2021). MODIS/Terra Land Surface
Temperature/Emissivity 8-Day L3 Global 1km SIN Grid V061. NASA EOSDIS LP
DAAC.
[doi:10.5067/MODIS/MOD11A2.061](https://doi.org/10.5067/MODIS/MOD11A2.061)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
lst <- read_modis_lst(date = "2024-06-15",
                      region = terra::ext(138, 140, -36, -34))
}
```
