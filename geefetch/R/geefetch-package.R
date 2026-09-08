#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table data.table setDT rbindlist setnames setcolorder
#'   setattr is.data.table as.data.table copy
#' @importFrom lifecycle deprecated
#' @importFrom jsonlite fromJSON
#' @importFrom parallel detectCores
#' @importFrom qs2 qd_save qd_read qs_save qs_read
#' @importFrom rlang abort warn inform is_installed arg_match check_required
#'   caller_env `%||%`
#' @importFrom utils packageVersion
## usethis namespace: end
NULL

# Package-level environment for session state (auth tokens, memory cache)
.geefetch_env <- new.env(parent = emptyenv())


#' Shared parameter documentation
#'
#' @description
#' Not a real function; exists so other topics can inherit the parameter
#' descriptions below via `@inheritParams` instead of repeating them.
#'
#' @param did Character. Normalised dataset ID.
#' @param meta List. Dataset metadata from `.GEE_META`.
#' @param date Character or Date. Acquisition date in `"YYYY-MM-DD"` format.
#' @param coords data.table with `point_id`, `lon`, `lat` columns.
#' @param region An [sf::sf], [sf::st_sfc()], or [terra::ext()] object
#'   defining the spatial extent. Required.
#' @param bands Character or NULL (use `meta$bands`).
#' @param backend Character. `"rest"` (default) or `"rgee"`.
#' @param cache Logical. Cache results in an in-session memory store?
#'   Default `TRUE`. Persisting to disk under [tools::R_user_dir()]
#'   additionally requires `options(geefetch.cache.disk = TRUE)` or
#'   [gee_cache_disk()]; see [gee_clear_cache()] to clear either store.
#' @param verbose Logical. Print progress table and status messages?
#'   Default `TRUE`.
#' @param max_tries Integer. Maximum retry attempts for network failures.
#'   Default `3L`.
#' @param initial_delay Numeric. Initial retry delay in seconds, doubling
#'   on each attempt. Default `1`.
#'
#' @returns No value. This topic only documents arguments shared by several
#'   functions.
#' @name gee_shared_params
#' @keywords internal
NULL
