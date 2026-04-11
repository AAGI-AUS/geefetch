# Batch-extract GEE data at point locations

Extracts values from multiple GEE datasets at one or more point
locations across a date range. Returns a single
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with one row per location-date combination and one column per dataset.

This is the primary function for building environmental covariate tables
for modelling.

## Usage

``` r
collect_gee_data(
  lon = NULL,
  lat = NULL,
  xy = NULL,
  date_range,
  datasets = NULL,
  depth = "0-5",
  stat = "mean",
  backend = c("rest", "rgee"),
  cache = TRUE,
  verbose = TRUE,
  na.rm = FALSE
)
```

## Arguments

- lon, lat:

  Numeric vectors of coordinates (WGS84). Ignored if `xy` is provided.

- xy:

  A data.frame, matrix, or
  [sf::sf](https://r-spatial.github.io/sf/reference/sf.html) object with
  point locations. Must contain columns named `lon`/`lat`, `x`/`y`, or
  `longitude`/`latitude`, or be an sf POINT geometry.

- date_range:

  A length-2 character or Date vector (`c(start, end)`), or an explicit
  vector of dates.

- datasets:

  Character vector of dataset names or aliases. Use
  [`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
  to list available options.

- depth:

  Character. For SLGA soil datasets: depth layer(s). `"0-5"`, `"5-15"`,
  ..., `"100-200"`, or `"all"`. Default `"0-5"`.

- stat:

  Character. For SLGA soil datasets: statistic. `"mean"`, `"ci_lower"`,
  `"ci_upper"`. Default `"mean"`.

- backend:

  Character. `"rest"` (default) or `"rgee"`.

- cache:

  Logical. Default `TRUE`.

- verbose:

  Logical. Print progress table and status messages? Default `TRUE`.

- na.rm:

  Logical. Remove rows where all dataset columns are NA? Default
  `FALSE`.

## Value

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns:

- date:

  Date of extraction

- lon, lat:

  Coordinates (always included)

- point_id:

  Integer point identifier

- :

  One column per requested dataset

## Column naming

Each dataset produces a column named after its normalised ID (e.g.,
`modis_ndvi`, `era5_temp`, `srtm_elevation`). Static datasets have their
value replicated across all dates.

## Error handling

Failed extractions for individual dataset-date combinations produce `NA`
values with a warning. Execution continues for remaining datasets. This
matches `nert`'s resilient batch behaviour.

## See also

[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
for single-dataset reads,
[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md)
to list available datasets.

## Examples

``` r
if (FALSE) { # interactive()
# Single location, multiple datasets
dt <- collect_gee_data(
  lon = 138.6, lat = -34.9,
  date_range = c("2024-01-01", "2024-03-31"),
  datasets = c("modis_ndvi", "era5_temp")
)

# Multiple locations from a data.frame
sites <- data.frame(lon = c(138.6, 149.1), lat = c(-34.9, -35.3))
dt <- collect_gee_data(
  xy = sites,
  date_range = c("2024-01-01", "2024-12-31"),
  datasets = c("modis_ndvi", "era5_temp", "srtm_elevation")
)
}
```
