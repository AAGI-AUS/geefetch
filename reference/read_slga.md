# Read SLGA soil data from Google Earth Engine

**\[experimental\]**

Reads CSIRO Soil and Landscape Grid of Australia (SLGA) data from Google
Earth Engine. Supports 7 soil attributes, 6 depth layers, and 3
statistics. This is a static dataset (no date required).

## Usage

``` r
read_slga(
  region,
  collection = c("CLY", "SND", "SLT", "AWC", "BDW", "PHC", "NTO"),
  depth = "0-5",
  stat = c("mean", "ci_lower", "ci_upper"),
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
)
```

## Arguments

- region:

  An [sf::sf](https://r-spatial.github.io/sf/reference/sf.html),
  [`sf::st_sfc()`](https://r-spatial.github.io/sf/reference/sfc.html),
  or
  [`terra::ext()`](https://rspatial.github.io/terra/reference/ext.html)
  object defining the spatial extent. Required.

- collection:

  Character. Soil attribute to extract. One of:

  - `"CLY"` — Clay content (percent)

  - `"SND"` — Sand content (percent)

  - `"SLT"` — Silt content (percent)

  - `"AWC"` — Available water capacity (mm)

  - `"BDW"` — Bulk density (g/cm3)

  - `"PHC"` — pH (CaCl2)

  - `"NTO"` — Total nitrogen (percent)

  Default `"CLY"`.

- depth:

  Character. Depth layer. One of `"0-5"`, `"5-15"`, `"15-30"`,
  `"30-60"`, `"60-100"`, `"100-200"`. Default `"0-5"`.

- stat:

  Character. Statistic. `"mean"` (default), `"ci_lower"` (5th
  percentile), or `"ci_upper"` (95th percentile).

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
SpatRaster. CRS: EPSG:4326. Values depend on the collection (e.g.,
percent for clay, pH units for PHC).

## Data availability

Static dataset. Australia only. 90 m spatial resolution. 6 depth layers:
0-5, 5-15, 15-30, 30-60, 60-100, 100-200 cm.

## References

Viscarra Rossel, R.A., Chen, C., Grundy, M.J., Searle, R., Clifford, D.
& Campbell, P.H. (2015). The Australian three-dimensional soil grid:
Australia's contribution to the GlobalSoilMap project. Soil Research,
53(8), 845-864. [doi:10.1071/SR14366](https://doi.org/10.1071/SR14366)

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
[`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md),
[`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)

## Examples

``` r
if (FALSE) { # interactive()
# Clay content, 0-5cm, mean
clay <- read_slga(region = terra::ext(138, 140, -36, -34))

# pH at 30-60cm depth
ph <- read_slga(region = terra::ext(138, 140, -36, -34),
                collection = "PHC", depth = "30-60")

# Sand content with confidence interval
sand_lo <- read_slga(region = terra::ext(138, 140, -36, -34),
                     collection = "SND", stat = "ci_lower")
}
```
