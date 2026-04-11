# Package index

## GEE Readers

Extract raster data from Google Earth Engine collections.

- [`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
  : Read data from Google Earth Engine
- [`read_modis_ndvi()`](https://aagi-aus.github.io/geefetch/reference/read_modis_ndvi.md)
  : Read MODIS Terra NDVI from Google Earth Engine
- [`read_modis_lst()`](https://aagi-aus.github.io/geefetch/reference/read_modis_lst.md)
  : Read MODIS Terra Land Surface Temperature from Google Earth Engine
- [`read_era5()`](https://aagi-aus.github.io/geefetch/reference/read_era5.md)
  : Read ERA5-Land climate data from Google Earth Engine
- [`read_chirps()`](https://aagi-aus.github.io/geefetch/reference/read_chirps.md)
  : Read CHIRPS daily precipitation from Google Earth Engine
- [`read_srtm()`](https://aagi-aus.github.io/geefetch/reference/read_srtm.md)
  : Read SRTM elevation data from Google Earth Engine
- [`read_slga()`](https://aagi-aus.github.io/geefetch/reference/read_slga.md)
  : Read SLGA soil data from Google Earth Engine
- [`read_sentinel2()`](https://aagi-aus.github.io/geefetch/reference/read_sentinel2.md)
  : Read Sentinel-2 NDVI from Google Earth Engine
- [`read_landsat()`](https://aagi-aus.github.io/geefetch/reference/read_landsat.md)
  : Read Landsat 9 NDVI from Google Earth Engine
- [`read_worldclim()`](https://aagi-aus.github.io/geefetch/reference/read_worldclim.md)
  : Read WorldClim bioclimatic variables from Google Earth Engine

## Batch Extraction

Extract point values across multiple locations, dates, and datasets.

- [`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
  : Batch-extract GEE data at point locations

## Authentication

Authenticate with Google Earth Engine and check connection status.

- [`gee_auth()`](https://aagi-aus.github.io/geefetch/reference/gee_auth.md)
  : Authenticate with Google Earth Engine
- [`gee_status()`](https://aagi-aus.github.io/geefetch/reference/gee_status.md)
  : Check GEE connection status
- [`gee_setup()`](https://aagi-aus.github.io/geefetch/reference/gee_setup.md)
  : Guided first-time setup for GEE access

## Utilities

Browse datasets, register custom collections, manage cache.

- [`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
  : List available GEE datasets
- [`gee_register_dataset()`](https://aagi-aus.github.io/geefetch/reference/gee_register_dataset.md)
  : Register a custom GEE dataset
- [`gee_clear_cache()`](https://aagi-aus.github.io/geefetch/reference/gee_clear_cache.md)
  : Clear the geefetch disk cache
