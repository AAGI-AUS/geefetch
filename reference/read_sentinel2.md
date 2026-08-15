# Read Sentinel-2 NDVI from Google Earth Engine

**\[experimental\]**

Computes NDVI from Copernicus Sentinel-2 MSI Level-2A harmonised surface
reflectance (COPERNICUS/S2_SR_HARMONIZED) on Google Earth Engine. Cloud
and shadow pixels are masked using the Scene Classification Layer (SCL).

## Usage

``` r
read_sentinel2(
  date,
  region,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
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
SpatRaster. CRS: EPSG:4326. Values: NDVI (-1 to 1). NA where SCL
indicates cloud, shadow, or snow.

## Data availability

2017-03-28 to present. ~5-day revisit. 10 m spatial resolution.

## References

European Space Agency. Copernicus Sentinel-2 MSI Level-2A.

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md),
[`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
ndvi <- read_sentinel2(date = "2024-06-15",
                       region = terra::ext(138, 139, -35, -34))
}
```
