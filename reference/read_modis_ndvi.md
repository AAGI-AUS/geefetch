# Read MODIS Terra NDVI from Google Earth Engine

**\[experimental\]**

Reads MODIS/061/MOD13A2 (Terra Vegetation Indices 16-Day L3 1km) from
Google Earth Engine for the specified date. Returns a
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
SpatRaster with QA-masked, scaled NDVI values (range: approximately -0.2
to 1.0).

## Usage

``` r
read_modis_ndvi(
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

  Character or Date. Acquisition date in `"YYYY-MM-DD"` format. The
  nearest available 16-day composite containing this date is returned.

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
SpatRaster. CRS: EPSG:4326. Values: NDVI (scaled, approximately -0.2 to
1.0). NA where QA indicates poor quality.

## Data availability

2000-02-18 to present. 16-day composites. 1 km spatial resolution.

## QA masking

Pixels with SummaryQA \> 1 (snow/ice, cloudy) are masked to NA. Only
good (0) and marginal (1) quality pixels are retained.

## References

Didan, K. (2021). MODIS/Terra Vegetation Indices 16-Day L3 Global 1km
SIN Grid V061. NASA EOSDIS Land Processes Distributed Active Archive
Center.
[doi:10.5067/MODIS/MOD13A2.061](https://doi.org/10.5067/MODIS/MOD13A2.061)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
for the general dispatcher,
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
for batch point extraction.

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md),
[`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md),
[`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
ndvi <- read_modis_ndvi(date = "2024-06-15",
                        region = terra::ext(138, 140, -36, -34))
terra::plot(ndvi)
}
```
