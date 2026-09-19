# test-cache.R — Tests for the caching layer

test_that(".cache_hash produces consistent SHA256 hashes", {
  h1 <- .cache_hash("modis_ndvi", list(date = "2024-06-15"))
  h2 <- .cache_hash("modis_ndvi", list(date = "2024-06-15"))
  h3 <- .cache_hash("modis_ndvi", list(date = "2024-06-16"))

  expect_identical(h1, h2)
  expect_false(h1 == h3)
  expect_gt(nchar(h1), 0L) # digest length depends on algo
})

test_that(".cache_hash is order-independent for parameter names", {
  h1 <- .cache_hash("test", list(a = 1, b = 2))
  h2 <- .cache_hash("test", list(b = 2, a = 1))
  expect_identical(h1, h2)
})

test_that("cache round-trip works for data.frames", {
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = withr::local_tempdir()
  ))

  # Ensure clean state
  .geefetch_env$mem_cache <- NULL

  did <- "test_dataset"
  params <- list(date = "2024-01-01")
  result <- data.frame(x = 1:3, y = letters[1:3])

  # Should be empty initially
  expect_null(.cache_get(did, params))

  # Set
  .cache_set(did, params, result)

  # Get (memory)
  cached <- .cache_get(did, params)
  expect_identical(nrow(cached), 3L)

  # Clear memory, force disk read
  .geefetch_env$mem_cache <- NULL
  cached_disk <- .cache_get(did, params)
  expect_identical(nrow(cached_disk), 3L)
})

test_that("cache round-trip works for non-data.frame objects", {
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = withr::local_tempdir()
  ))
  .geefetch_env$mem_cache <- NULL

  did <- "test_raster"
  params <- list(date = "2024-01-01")
  result <- list(type = "raster", values = 1:10)

  .cache_set(did, params, result)
  .geefetch_env$mem_cache <- NULL

  cached <- .cache_get(did, params)
  expect_identical(cached$type, "raster")
  expect_identical(cached$values, 1:10)
})

test_that("cache round-trip preserves a mixed-type data.table exactly", {
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = withr::local_tempdir()
  ))
  .geefetch_env$mem_cache <- NULL

  did <- "test_dt_types"
  params <- list(date = "2024-01-01")
  result <- data.table(
    point_id = 1:4,
    date = as.Date("2024-01-01") + 0:3,
    site = c("north", "south", "east", "west"),
    value = c(1.5, 2.25, NA_real_, 4.75)
  )

  .cache_set(did, params, result)
  .geefetch_env$mem_cache <- NULL

  cached <- .cache_get(did, params)
  expect_true(is.data.table(cached))
  expect_identical(cached, result)
})

test_that("cache round-trip preserves a numeric vector exactly", {
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = withr::local_tempdir()
  ))
  .geefetch_env$mem_cache <- NULL

  did <- "test_numeric_vector"
  params <- list(date = "2024-01-01")
  result <- c(1.1, 2.2, NA_real_, 4.4, -5.5)

  .cache_set(did, params, result)
  .geefetch_env$mem_cache <- NULL

  cached <- .cache_get(did, params)
  expect_identical(cached, result)
})

test_that("an old-format cache file is missed, not misread", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = tmp
  ))
  .geefetch_env$mem_cache <- NULL

  did <- "test_legacy"
  params <- list(date = "2024-01-01")

  # Pre-qs2 keys hashed (dataset, params) with no format stamp; write an
  # .rds file at the path that key would have produced.
  legacy_hash <- digest::digest(
    list(dataset = did, params = params[order(names(params))]),
    algo = "sha256"
  )
  legacy_path <- file.path(tmp, paste0(legacy_hash, ".rds"))
  saveRDS(data.frame(x = 1), legacy_path)

  # The current key includes .CACHE_FORMAT, so it never resolves to the
  # legacy file: a miss, not a read of stale/incompatible data.
  expect_null(.cache_get(did, params))
  expect_true(file.exists(legacy_path)) # untouched, not even inspected
})

test_that("gee_clear_cache removes files", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = tmp
  ))
  .geefetch_env$mem_cache <- NULL

  # Create some cache entries
  .cache_set("d1", list(a = 1), data.frame(x = 1))
  .cache_set("d2", list(a = 2), data.frame(x = 2))

  files_before <- list.files(tmp, pattern = "\\.(qdata|qs2|tif)$")
  expect_gte(length(files_before), 2L)

  n <- gee_clear_cache()
  expect_identical(n, length(files_before))

  files_after <- list.files(tmp, pattern = "\\.(qdata|qs2|tif)$")
  expect_length(files_after, 0L)
})

test_that("gee_clear_cache older_than filter works", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = tmp
  ))
  .geefetch_env$mem_cache <- NULL

  # Create a cache entry
  .cache_set("d1", list(a = 1), data.frame(x = 1))

  # File is brand new, so older_than = 1 should not remove it
  n <- gee_clear_cache(older_than = 1)
  expect_identical(n, 0L)

  files <- list.files(tmp, pattern = "\\.(qdata|qs2|tif)$")
  expect_gte(length(files), 1L)
})

test_that("gee_clear_cache also removes on-disk files from old formats", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = tmp
  ))
  .geefetch_env$mem_cache <- NULL

  writeLines("legacy rds", file.path(tmp, "legacy1.rds"))
  writeLines("legacy fst", file.path(tmp, "legacy2.fst"))
  .cache_set("d1", list(a = 1), data.frame(x = 1))

  n <- gee_clear_cache()
  expect_identical(n, 3L)
  expect_length(list.files(tmp), 0L)
})

test_that("cache handles corrupt files gracefully", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = tmp
  ))
  .geefetch_env$mem_cache <- NULL

  # Write a corrupt file at the current-format path
  hash <- .cache_hash("corrupt", list(a = 1))
  writeLines("not valid data", file.path(tmp, paste0(hash, ".qdata")))

  # Should return NULL and remove the corrupt file
  expect_warning(
    result <- .cache_get("corrupt", list(a = 1)),
    "Corrupt cache file"
  )
  expect_null(result)
  expect_false(file.exists(file.path(tmp, paste0(hash, ".qdata"))))
})

test_that(".cache_set falls back to memory-only when the disk write fails", {
  withr::local_options(list(
    geefetch.cache.disk = TRUE,
    geefetch.cache_dir = withr::local_tempdir()
  ))
  .geefetch_env$mem_cache <- NULL

  did <- "test_valueless_raster"
  params <- list(date = "2024-01-01")

  # A SpatRaster template with no cell values: terra::writeRaster() cannot
  # write it to disk, so .cache_set() should warn and keep the result in
  # the memory cache only.
  result <- terra::rast(nrows = 10, ncols = 10)

  expect_warning(
    .cache_set(did, params, result),
    "Failed to write to disk cache"
  )

  cached <- .cache_get(did, params)
  expect_s4_class(cached, "SpatRaster")
})
