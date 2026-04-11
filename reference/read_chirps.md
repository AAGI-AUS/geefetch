# Read CHIRPS daily precipitation from Google Earth Engine

Reads UCSB-CHG/CHIRPS/DAILY (Climate Hazards Group InfraRed
Precipitation With Station Data) from Google Earth Engine. Returns a
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
SpatRaster with precipitation in mm/day.

## Usage

``` r
read_chirps(
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

  Character or Date. Date in `"YYYY-MM-DD"` format.

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
SpatRaster. CRS: EPSG:4326. Values: precipitation in mm/day.

## Data availability

1981-01-01 to near-present. Daily. ~5.5 km spatial resolution. Coverage:
50S-50N (land only).

## References

Funk, C. et al. (2015). The climate hazards infrared precipitation with
stations – a new environmental record for monitoring extremes.
Scientific Data, 2, 150066.
[doi:10.1038/sdata.2015.66](https://doi.org/10.1038/sdata.2015.66)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md),
[`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
precip <- read_chirps(date = "2024-06-15",
                      region = terra::ext(138, 140, -36, -34))
}
```
