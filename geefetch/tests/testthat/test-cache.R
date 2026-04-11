# test-cache.R — Tests for the caching layer

test_that(".cache_hash produces consistent SHA256 hashes", {
  h1 <- .cache_hash("modis_ndvi", list(date = "2024-06-15"))
  h2 <- .cache_hash("modis_ndvi", list(date = "2024-06-15"))
  h3 <- .cache_hash("modis_ndvi", list(date = "2024-06-16"))

  expect_equal(h1, h2)
  expect_false(h1 == h3)
  expect_true(nchar(h1) > 0L)  # digest length depends on algo
})

test_that(".cache_hash is order-independent for parameter names", {
  h1 <- .cache_hash("test", list(a = 1, b = 2))
  h2 <- .cache_hash("test", list(b = 2, a = 1))
  expect_equal(h1, h2)
})

test_that("cache round-trip works for data.frames", {
  withr::local_options(list(geefetch.cache_dir = withr::local_tempdir()))

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
  expect_equal(nrow(cached), 3L)

  # Clear memory, force disk read
  .geefetch_env$mem_cache <- NULL
  cached_disk <- .cache_get(did, params)
  expect_equal(nrow(cached_disk), 3L)
})

test_that("cache round-trip works for non-data.frame objects", {
  withr::local_options(list(geefetch.cache_dir = withr::local_tempdir()))
  .geefetch_env$mem_cache <- NULL

  did <- "test_raster"
  params <- list(date = "2024-01-01")
  result <- list(type = "raster", values = 1:10)

  .cache_set(did, params, result)
  .geefetch_env$mem_cache <- NULL

  cached <- .cache_get(did, params)
  expect_equal(cached$type, "raster")
  expect_equal(cached$values, 1:10)
})

test_that("gee_clear_cache removes files", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  .geefetch_env$mem_cache <- NULL

  # Create some cache entries
  .cache_set("d1", list(a = 1), data.frame(x = 1))
  .cache_set("d2", list(a = 2), data.frame(x = 2))

  files_before <- list.files(tmp, pattern = "\\.(fst|rds)$")
  expect_true(length(files_before) >= 2L)

  n <- gee_clear_cache()
  expect_equal(n, length(files_before))

  files_after <- list.files(tmp, pattern = "\\.(fst|rds)$")
  expect_equal(length(files_after), 0L)
})

test_that("gee_clear_cache older_than filter works", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  .geefetch_env$mem_cache <- NULL

  # Create a cache entry
  .cache_set("d1", list(a = 1), data.frame(x = 1))

  # File is brand new, so older_than = 1 should not remove it
  n <- gee_clear_cache(older_than = 1)
  expect_equal(n, 0L)

  files <- list.files(tmp, pattern = "\\.(fst|rds)$")
  expect_true(length(files) >= 1L)
})

test_that("cache handles corrupt files gracefully", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(geefetch.cache_dir = tmp))
  .geefetch_env$mem_cache <- NULL

  # Write a corrupt file
  hash <- .cache_hash("corrupt", list(a = 1))
  writeLines("not valid data", file.path(tmp, paste0(hash, ".rds")))

  # Should return NULL and remove the corrupt file
  expect_warning(
    result <- .cache_get("corrupt", list(a = 1)),
    "Corrupt cache file"
  )
  expect_null(result)
  expect_false(file.exists(file.path(tmp, paste0(hash, ".rds"))))
})
