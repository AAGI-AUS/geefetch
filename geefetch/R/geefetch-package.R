#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table data.table setDT rbindlist setnames setcolorder
#'   setattr is.data.table as.data.table
#' @importFrom lifecycle deprecated
#' @importFrom rlang abort warn inform is_installed arg_match check_required
#'   caller_env `%||%`
#' @importFrom utils packageVersion
## usethis namespace: end
NULL

# Package-level environment for session state (auth tokens, memory cache)
.geefetch_env <- new.env(parent = emptyenv())
