# Read WorldClim bioclimatic variables from Google Earth Engine

Reads WorldClim V2 bioclimatic variables (WORLDCLIM/V2/BIO) from Google
Earth Engine. This is a static dataset representing 1970-2000 climate
normals at ~1 km resolution.

## Usage

``` r
read_worldclim(
  region,
  variable = "bio01",
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1
)
```

## Arguments

- region:

  An [sf::sf](https://r-spatial.github.io/sf/reference/sf.html),
  [`sf::st_sfc()`](https://r-spatial.github.io/sf/reference/sfc.html),
  or
  [`terra::ext()`](https://rspatial.github.io/terra/reference/ext.html)
  object defining the spatial extent. Required.

- variable:

  Character. Bioclimatic variable band name. One of `"bio01"` through
  `"bio19"`. Default `"bio01"` (annual mean temperature, degrees C x
  10).

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
SpatRaster. CRS: EPSG:4326. Values depend on the variable (see WorldClim
documentation).

## Data availability

Static (1970-2000 normals). Global land. ~1 km spatial resolution.

## Variables

- bio01: Annual Mean Temperature (deg C x 10)

- bio02: Mean Diurnal Range

- bio03: Isothermality

- bio04: Temperature Seasonality

- bio05-bio11: Various temperature metrics

- bio12: Annual Precipitation (mm)

- bio13-bio19: Various precipitation metrics

## References

Fick, S.E. & Hijmans, R.J. (2017). WorldClim 2: new 1km spatial
resolution climate surfaces for global land areas. International Journal
of Climatology, 37(12), 4302-4315.
[doi:10.1002/joc.5086](https://doi.org/10.1002/joc.5086)

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md),
[`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md),
[`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md),
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md),
[`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md),
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md)

## Examples

``` r
if (FALSE) { # interactive()
# Annual mean temperature
temp <- read_worldclim(region = terra::ext(138, 140, -36, -34))

# Annual precipitation
precip <- read_worldclim(region = terra::ext(138, 140, -36, -34),
                         variable = "bio12")
}
```
