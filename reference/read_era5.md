# Read ERA5-Land climate data from Google Earth Engine

**\[experimental\]**

Reads ERA5-Land Daily Aggregated data (ECMWF/ERA5_LAND/DAILY_AGGR) from
Google Earth Engine. Supports temperature and precipitation variables
via the `variable` argument.

## Usage

``` r
read_era5(
  date,
  region,
  variable = c("temperature", "precipitation"),
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
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

- variable:

  Character. `"temperature"` (default) or `"precipitation"`.

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
SpatRaster. CRS: EPSG:4326. Values:

- Temperature: degrees Celsius (converted from Kelvin)

- Precipitation: mm (converted from metres)

## Data availability

1950-01-01 to present. Daily. ~11 km spatial resolution.

## References

Munoz Sabater, J. (2019). ERA5-Land hourly data from 1950 to present.
Copernicus Climate Change Service (C3S) Climate Data Store (CDS).
[doi:10.24381/cds.e2161bac](https://doi.org/10.24381/cds.e2161bac)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
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
temp <- read_era5(date = "2024-06-15",
                  region = terra::ext(138, 140, -36, -34))

precip <- read_era5(date = "2024-06-15",
                    region = terra::ext(138, 140, -36, -34),
                    variable = "precipitation")
}
```
