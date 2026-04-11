# Adding Custom GEE Datasets

## Overview

geefetch ships with 19 built-in datasets, but Google Earth Engine hosts
thousands of collections. You can register any GEE collection for use
with
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
and
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
using
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md).

## Browsing built-in datasets

``` r
library(geefetch)

# Full catalogue
gee_datasets()

# Filter by domain
gee_datasets(domain = "Vegetation")
gee_datasets(domain = "Soil (Global)")
```

## Registering a custom dataset

To add a new GEE collection, you need:

1.  The **GEE collection ID** (find it in the [GEE Data
    Catalog](https://developers.google.com/earth-engine/datasets))
2.  The **band name(s)** to extract
3.  The **spatial resolution** (scale in metres)
4.  The **temporal resolution** (`"daily"`, `"8day"`, `"16day"`,
    `"monthly"`, `"5day"`, or `"static"`)

### Example: Global Surface Water

``` r
gee_register_dataset(
  name        = "gsw_occurrence",
  collection  = "JRC/GSW1_4/GlobalSurfaceWater",
  bands       = "occurrence",
  scale       = 30L,
  temporal    = "static",
  description = "JRC Global Surface Water Occurrence 30m",
  domain      = "Hydrology",
  citation    = "Pekel et al. (2016). doi:10.1038/nature20584"
)
```

    ## v Registered custom dataset "gsw_occurrence".
    ## i Collection: "JRC/GSW1_4/GlobalSurfaceWater"
    ## i Available via read_gee("gsw_occurrence") and collect_gee_data().

### Example: MODIS Land Cover

``` r
gee_register_dataset(
  name         = "modis_lc",
  collection   = "MODIS/061/MCD12Q1",
  bands        = "LC_Type1",
  scale        = 500L,
  temporal     = "static",
  description  = "MODIS Land Cover Type 1 (IGBP) 500m",
  domain       = "Land cover",
  scale_factor = 1,
  offset       = 0
)
```

## Using registered datasets

Once registered, the dataset works with the dispatcher and batch
extraction exactly like built-in datasets:

``` r
# Single extraction
water <- read_gee("gsw_occurrence",
                   region = terra::ext(138, 140, -36, -34))

# Batch extraction
dt <- collect_gee_data(
  lon = c(138.6, 149.1),
  lat = c(-34.9, -35.3),
  date_range = c("2024-01-01", "2024-01-01"),
  datasets = c("gsw_occurrence", "srtm_elevation")
)
```

## What the generic handler does (and doesn’t do)

Custom datasets use the **generic handler**, which:

- Loads the collection
- Filters by date (for time-series datasets)
- Selects the specified bands
- Applies `scale_factor` and `offset`
- Extracts raster or point values

The generic handler does **not**:

- Apply QA masking (no `qa_band` processing)
- Compute derived indices (e.g., NDVI from two bands)
- Handle complex multi-band logic

If you need QA masking or computed indices, consider opening a GitHub
issue to request a specialised handler.

## Session scope

Registered datasets persist for the current R session only. To use them
across sessions, add the
[`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)
call to your script or `.Rprofile`.

## Contributing handlers upstream

If your dataset is widely useful, consider contributing a built-in
handler to geefetch:

1.  Fork the repository
2.  Add metadata to `.GEE_META` in `R/handler_registry.R`
3.  Add an alias to `.GEE_ALIASES`
4.  Write a handler in `R/handlers.R` (or rely on the generic handler)
5.  Write a convenience alias in `R/read_*.R`
6.  Add tests in `tests/testthat/`
7.  Open a pull request
