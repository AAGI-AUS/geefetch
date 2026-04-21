# cache.R — Disk and memory caching for GEE extraction results
#
# Two-layer cache:
#   1. In-memory (session-level) — keyed list in .geefetch_env$mem_cache
#   2. On-disk — format-aware:
#      - data.frames: .fst (if available) or .rds
#      - SpatRaster: .tif (GeoTIFF via terra::writeRaster)
#      - Other objects: .rds
#
# Cache keys are SHA256 hashes of (dataset_id, extraction_parameters).
# TTL: 30 days for dynamic datasets, infinite for static (SRTM, SLGA).

#' Get the cache directory path
#'
#' Uses `tools::R_user_dir()` which is CRAN-compliant and cross-platform.
#'
#' @returns Character. Path to the cache directory.
#'
#' @noRd
.cache_dir <- function() {
  getOption("geefetch.cache_dir", tools::R_user_dir("geefetch", "cache"))
}


#' Ensure the cache directory exists
#'
#' @returns Character. Path to the (now existing) cache directory.
#'
#' @noRd
.cache_ensure_dir <- function() {
  d <- .cache_dir()
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }
  d
}


#' Compute a cache key hash
#'
#' Deterministic SHA256 of the dataset ID and all extraction parameters.
#'
#' @param did Character. Normalised dataset ID.
#' @param params Named list. Extraction parameters (date, region, bands, etc.).
#'
#' @returns Character. Hex SHA256 hash string.
#'
#' @noRd
.cache_hash <- function(did, params) {
  # Sort parameter names for deterministic hashing
  key_parts <- list(
    dataset = did,
    params = params[order(names(params))]
  )
  digest::digest(key_parts, algo = "sha256")
}


#' Determine the disk cache file extension for an object
#' @noRd
.cache_ext <- function(result) {
  if (inherits(result, "SpatRaster")) {
    ".tif"
  } else if (is.data.frame(result) && rlang::is_installed("fst")) {
    ".fst"
  } else {
    ".rds"
  }
}


#' Find an existing cache file for a given hash
#' @noRd
.cache_find_file <- function(d, hash) {
  for (ext in c(".tif", ".fst", ".rds")) {
    fpath <- file.path(d, paste0(hash, ext))
    if (file.exists(fpath)) return(fpath)
  }
  NULL
}


#' Retrieve a cached result
#'
#' Checks memory cache first, then disk. Respects TTL for dynamic datasets.
#'
#' @param did Character. Normalised dataset ID.
#' @param params Named list. Extraction parameters.
#'
#' @returns The cached object, or NULL if not found / expired.
#'
#' @noRd
.cache_get <- function(did, params) {
  hash <- .cache_hash(did, params)

  # Layer 1: memory cache
  mem <- .geefetch_env$mem_cache[[hash]]
  if (!is.null(mem)) {
    return(mem)
  }

  # Layer 2: disk cache
  d <- .cache_dir()
  if (!dir.exists(d)) {
    return(NULL)
  }

  fpath <- .cache_find_file(d, hash)
  if (is.null(fpath)) {
    return(NULL)
  }

  # Check TTL for dynamic datasets
  meta <- .gee_combined_meta()[[did]]
  is_static <- !is.null(meta) && identical(meta$temporal, "static")

  if (!is_static) {
    age_days <- as.numeric(
      difftime(Sys.time(), file.mtime(fpath), units = "days")
    )
    ttl <- getOption("geefetch.cache_ttl", 30)
    if (age_days > ttl) {
      unlink(fpath)
      return(NULL)
    }
  }

  # Read from disk — format-aware
  result <- tryCatch(
    {
      if (endsWith(fpath, ".tif")) {
        terra::rast(fpath)
      } else if (endsWith(fpath, ".fst") && rlang::is_installed("fst")) {
        fst::read_fst(fpath, as.data.table = TRUE)
      } else {
        readRDS(fpath)
      }
    },
    error = function(e) {
      cli::cli_warn(c(
        `!` = "Corrupt cache file removed: {.path {fpath}}",
        i = "Will re-fetch from GEE."
      ))
      unlink(fpath)
      NULL
    }
  )

  # Promote to memory cache
  if (!is.null(result)) {
    if (is.null(.geefetch_env$mem_cache)) {
      .geefetch_env$mem_cache <- list()
    }
    .geefetch_env$mem_cache[[hash]] <- result
  }

  result
}


#' Store a result in cache
#'
#' Writes to both memory and disk. SpatRaster objects are written as
#' GeoTIFF files (not RDS, which would lose the raster data across
#' sessions). Data frames use fst (fast) or RDS (fallback).
#'
#' @param did Character. Normalised dataset ID.
#' @param params Named list. Extraction parameters.
#' @param result The object to cache.
#'
#' @returns NULL (invisibly).
#'
#' @noRd
.cache_set <- function(did, params, result) {
  hash <- .cache_hash(did, params)

  # Memory cache
  if (is.null(.geefetch_env$mem_cache)) {
    .geefetch_env$mem_cache <- list()
  }
  .geefetch_env$mem_cache[[hash]] <- result

  # Disk cache — format-aware
  d <- .cache_ensure_dir()
  ext <- .cache_ext(result)
  fpath <- file.path(d, paste0(hash, ext))

  tryCatch(
    {
      if (ext == ".tif") {
        terra::writeRaster(result, fpath, overwrite = TRUE)
      } else if (ext == ".fst") {
        fst::write_fst(result, fpath)
      } else {
        saveRDS(result, fpath)
      }
    },
    error = function(e) {
      cli::cli_warn(c(
        `!` = "Failed to write to disk cache.",
        i = "Result is cached in memory only for this session.",
        i = "Error: {conditionMessage(e)}"
      ))
    }
  )

  invisible(NULL)
}


#' Clear the geefetch disk cache
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Removes cached extraction results from disk. Optionally filter by
#' age to keep recent results.
#'
#' @param older_than Numeric. Only remove cache files older than this
#'   many days. Default `NULL` removes all files.
#'
#' @returns Invisibly returns the number of cache files removed.
#'
#' @family utilities
#' @seealso [gee_status()] to check cache size.
#'
#' @examplesIf interactive()
#' # Clear everything
#' gee_clear_cache()
#'
#' # Clear only files older than 7 days
#' gee_clear_cache(older_than = 7)
#'
#' @export
gee_clear_cache <- function(older_than = NULL) {
  d <- .cache_dir()
  if (!dir.exists(d)) {
    cli::cli_inform("Cache directory does not exist. Nothing to clear.")
    return(invisible(0L))
  }

  files <- list.files(
    d,
    pattern = "\\.(fst|rds|tif)$",
    full.names = TRUE
  )

  if (length(files) == 0L) {
    cli::cli_inform("Cache is empty. Nothing to clear.")
    return(invisible(0L))
  }

  if (!is.null(older_than)) {
    ages <- as.numeric(
      difftime(Sys.time(), file.mtime(files), units = "days")
    )
    files <- files[ages > older_than]
  }

  if (length(files) == 0L) {
    cli::cli_inform("No cache files match the age filter.")
    return(invisible(0L))
  }

  unlink(files)

  # Also clear memory cache
  .geefetch_env$mem_cache <- list()

  cli::cli_inform(c(
    v = "Removed {.val {length(files)}} cached file{?s}."
  ))

  invisible(length(files))
}
