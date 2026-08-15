# Read data from Google Earth Engine

**\[experimental\]**

Central dispatcher for all GEE dataset reads. Accepts a dataset
identifier (name or alias) and delegates to the appropriate internal
handler. For most use cases, prefer the convenience functions (e.g.,
[`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md))
which provide named parameters and dataset-specific documentation.

## Usage

``` r
read_gee(
  dataset_id,
  ...,
  backend = c("rest", "rgee"),
  cache = TRUE,
  max_tries = 3L,
  initial_delay = 1L
)
```

## Arguments

- dataset_id:

  Character. Dataset name or alias. Use
  [`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
  to list all available datasets.

- ...:

  Arguments passed to the dataset-specific handler. Common arguments
  include `date`, `region`, `collection`, `depth`. See the convenience
  function documentation for dataset-specific parameters.

- backend:

  Character. `"rest"` (default) or `"rgee"`. The REST backend requires
  no Python; the rgee backend supports advanced server-side
  computations.

- cache:

  Logical. Use disk cache for repeated queries? Default `TRUE`.

- max_tries:

  Integer. Maximum retry attempts for network failures. Default `3L`.

- initial_delay:

  Numeric. Initial delay in seconds before retry (doubles each attempt).
  Default `1`.

## Value

A
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
SpatRaster object.

## Supported datasets

Use
[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
to list all available datasets with metadata.

**Tier 1 — Specialised handlers (QA masking):**

- `modis_ndvi` — MODIS Terra NDVI 16-day 1km

- `modis_lst` — MODIS Terra LST 8-day 1km

- `era5_temp` — ERA5-Land daily 2m temperature

- `era5_precip` — ERA5-Land daily precipitation

- `chirps_precip` — CHIRPS daily precipitation

- `srtm_elevation` — NASA SRTM 30m elevation (static)

**Tier 2 — Specialised handlers (soil, computed indices):**

- `slga_cly`, `slga_snd`, `slga_slt`, `slga_awc`, `slga_bdw`,
  `slga_phc`, `slga_nto` — SLGA soil properties (Australia, static)

- `sentinel2_ndvi` — Sentinel-2 NDVI 10m (computed, cloud-masked)

- `landsat_ndvi` — Landsat 9 NDVI 30m (computed, cloud-masked)

**Tier 3 — Generic handler (global datasets):**

- `worldclim_bio` — WorldClim V1 bioclimatic variables ~1km (static)

- `openlandmap_soc` — OpenLandMap soil organic carbon 250m (static)

- `openlandmap_clay` — OpenLandMap clay content 250m (static)

- `openlandmap_ph` — OpenLandMap soil pH 250m (static)

**User-registered:** Any dataset added via
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)
is automatically dispatchable through the generic handler.

## See also

[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
for batch point extraction returning a
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html).

Other GEE readers:
[`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md),
[`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md),
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
# Using the dispatcher directly
ndvi <- read_gee("MODIS_NDVI", date = "2024-06-15",
                 region = terra::ext(138, 140, -36, -34))

# Aliases are case-insensitive
elev <- read_gee("srtm", region = terra::ext(138, 140, -36, -34))

# Equivalent convenience function (preferred)
ndvi <- read_modis_ndvi(date = "2024-06-15",
                        region = terra::ext(138, 140, -36, -34))
}
```
