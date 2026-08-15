# Register a custom GEE dataset

**\[experimental\]**

Adds a user-defined GEE collection to the geefetch registry for the
current R session. Once registered, the dataset can be used with
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)
and
[`collect_gee_data()`](https://aagi-aus.github.io/geefetch/reference/collect_gee_data.md)
like any built-in dataset.

## Usage

``` r
gee_register_dataset(
  name,
  collection,
  bands,
  scale,
  temporal,
  description,
  domain = "User-defined",
  qa_band = NA_character_,
  scale_factor = 1,
  offset = 0,
  citation = NA_character_
)
```

## Arguments

- name:

  Character. Short, unique identifier for the dataset (e.g.,
  `"soilgrids_ocs"`). Will be normalised to lowercase.

- collection:

  Character. GEE ImageCollection ID (e.g.,
  `"projects/soilgrids-isric/ocs"`).

- bands:

  Character vector. Band name(s) to extract.

- scale:

  Integer. Native resolution in metres.

- temporal:

  Character. Temporal resolution: `"daily"`, `"8day"`, `"16day"`,
  `"monthly"`, `"5day"`, or `"static"`.

- description:

  Character. Human-readable dataset description.

- domain:

  Character. Scientific domain (e.g., `"Soil"`, `"Vegetation"`). Default
  `"User-defined"`.

- qa_band:

  Character. QA band name, or `NA` if none. Default `NA_character_`.

- scale_factor:

  Numeric. Multiply raw values by this factor. Default `1`.

- offset:

  Numeric. Add this to values after scaling. Default `0`.

- citation:

  Character. Citation string. Default `NA_character_`.

## Value

`NULL`, invisibly. Called for side effects (registration).

## See also

[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md),
[`read_gee()`](https://aagi-aus.github.io/geefetch/reference/read_gee.md)

Other utilities:
[`gee_clear_cache()`](https://aagi-aus.github.io/geefetch/reference/gee_clear_cache.md),
[`gee_datasets()`](https://aagi-aus.github.io/geefetch/reference/gee_datasets.md),
[`gee_external_facts()`](https://aagi-aus.github.io/geefetch/reference/gee_external_facts.md)

## Examples

``` r
if (FALSE) { # interactive()
gee_register_dataset(
  name        = "soilgrids_ocs",
  collection  = "projects/soilgrids-isric/ocs",
  bands       = "ocs_0-30cm_mean",
  scale       = 250L,
  temporal    = "static",
  description = "SoilGrids Organic Carbon Stock 0-30cm"
)

# Now available in the registry
gee_datasets()
read_gee("soilgrids_ocs")
}
```
