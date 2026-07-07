# auth.R -- Google Earth Engine authentication via gargle
#
# Uses the same OAuth/service-account flow as googlesheets4, bigrquery,
# and googledrive. No Python, no reticulate.

# GEE OAuth scopes
.GEE_SCOPES <- c(
  "https://www.googleapis.com/auth/earthengine",
  "https://www.googleapis.com/auth/cloud-platform"
)

# Default GEE REST API project (can be overridden)
.GEE_DEFAULT_PROJECT <- "earthengine-legacy"


#' Authenticate with Google Earth Engine
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Authenticates with GEE using Google OAuth via the [gargle] package.
#' This is the same authentication flow used by
#' [googlesheets4](https://googlesheets4.tidyverse.org/),
#' [googledrive](https://googledrive.tidyverse.org/), and
#' [bigrquery](https://bigrquery.r-dbi.org/) -- no Python required.
#'
#' **Before calling `gee_auth()` for the first time**, complete the
#' one-time Google Cloud setup described in `vignette("geefetch")`
#' under "Authentication". In short: create a GCP project under a single
#' Google account, register it with Earth Engine for noncommercial use,
#' enable the Earth Engine API on that project. Then authenticate in R
#' using the project **number** (not the ID string) together with the
#' matching email address.
#'
#' For non-interactive use (CI, servers), use a service account JSON
#' key file via `gee_auth(path = "service-account.json")`.
#'
#' @param email Character. Google account email for OAuth. Should match
#'   the account that owns the Google Cloud project passed as `project`.
#'   Use `NA` to force interactive account selection, or `""` to suppress
#'   auto-selection. Default uses [gargle::gargle_oauth_email()].
#' @param path Character. Path to a service account JSON key file.
#'   Mutually exclusive with `email`.
#' @param project Character. Google Cloud project to use as the resource
#'   and quota project. **Pass the 12-digit project number as a string**
#'   (e.g. `"565208131613"`) rather than the project ID -- the number is
#'   unambiguous across Google accounts and avoids a common class of
#'   HTTP 403 errors where the OAuth token's implicit quota project
#'   differs from the intended resource project. The Earth Engine API
#'   must be enabled on this project. If `NULL` (default), falls back
#'   to `getOption("geefetch.project")` or `"earthengine-legacy"`.
#' @param scopes Character. OAuth scopes. Default includes Earth Engine
#'   and Cloud Platform scopes.
#' @param cache Character. Directory for OAuth token cache.
#'   Default: [gargle::gargle_oauth_cache()].
#'
#' @returns Invisibly returns the gargle token. Called for side effects.
#'
#' @section Project number vs ID:
#' Google Cloud projects have two identifiers: a string **ID** (e.g.
#' `geefetch-dev`) and a 12-digit **number** (e.g. `565208131613`). IDs
#' are not globally unique across accounts in the sense the user
#' experiences -- the same string can be registered by different
#' accounts and resolved against each account's catalogue at request
#' time, which leads to confusing cross-project errors. Numbers are
#' unambiguous. `geefetch` sends both the number-as-URL-path and an
#' `X-Goog-User-Project` header so that Google Earth Engine bills the
#' correct project regardless of the OAuth token's default binding.
#' You can find the number at
#' <https://console.cloud.google.com/home/dashboard?project=YOUR_ID>.
#'
#' @section Service accounts:
#' For automated pipelines (CI, HPC), create a service account in
#' Google Cloud Console, enable the Earth Engine API, and download
#' the JSON key. Then authenticate with:
#' ```r
#' gee_auth(
#'   project = "565208131613",
#'   path    = "path/to/service-account.json"
#' )
#' ```
#'
#' @section Persisting the project:
#' To avoid typing the project number every session, set it once in
#' your `.Rprofile`:
#' ```r
#' options(geefetch.project = "565208131613")
#' ```
#'
#' @family authentication
#' @seealso [gee_status()] to check authentication state,
#'   [gee_setup()] for guided first-time setup.
#'
#' @examplesIf interactive()
#' # Recommended form -- explicit project number + matching email.
#' gee_auth(
#'   project = "565208131613",
#'   email   = "me@@gmail.com"
#' )
#'
#' # Interactive OAuth (uses cached account)
#' gee_auth(project = "565208131613")
#'
#' # Service account (CI / non-interactive)
#' gee_auth(project = "565208131613", path = "path/to/service-account.json")
#'
#' @export
gee_auth <- function(
  email = gargle::gargle_oauth_email(),
  path = NULL,
  project = NULL,
  scopes = .GEE_SCOPES,
  cache = gargle::gargle_oauth_cache()
) {
  if (!is.null(path)) {
    # Service account flow
    if (!file.exists(path)) {
      cli::cli_abort(c(
        "Service account key file not found: {.path {path}}",
        i = "Download a key from Google Cloud Console > IAM > Service Accounts."
      ))
    }
    token <- gargle::credentials_service_account(
      scopes = scopes,
      path = path
    )
  } else {
    # OAuth flow
    token <- gargle::token_fetch(
      scopes = scopes,
      email = email,
      cache = cache
    )
  }

  if (is.null(token)) {
    cli::cli_abort(c(
      "GEE authentication failed.",
      i = "Run {.code gee_setup()} for guided setup instructions.",
      i = "Or try {.code gee_auth(email = NA)} to force account selection."
    ))
  }

  # Store token and project in package environment
  .geefetch_env$token <- token
  .geefetch_env$project <- project %||%
    getOption("geefetch.project", .GEE_DEFAULT_PROJECT)

  cli::cli_inform(c(
    v = "GEE authentication successful.",
    i = "Project: {.val {(.geefetch_env$project)}}"
  ))

  invisible(token)
}


#' Get the current GEE authentication token
#'
#' @returns A gargle token, or NULL if not authenticated.
#'
#' @noRd
.gee_token <- function() {
  .geefetch_env$token
}


#' Get the current GEE project ID
#'
#' @returns Character. The project ID.
#'
#' @noRd
.gee_project <- function() {
  .geefetch_env$project %||%
    getOption("geefetch.project", .GEE_DEFAULT_PROJECT)
}


#' Check that authentication is active
#'
#' Aborts with informative message if not authenticated.
#'
#' @param backend Character. `"rest"` or `"rgee"`.
#'
#' @noRd
.check_gee_auth <- function(backend = "rest") {
  if (backend == "rest") {
    if (is.null(.gee_token())) {
      cli::cli_abort(c(
        "Not authenticated with Google Earth Engine.",
        i = "Run {.code gee_auth()} to authenticate.",
        i = "Run {.code gee_setup()} for first-time setup instructions."
      ))
    }
  } else if (backend == "rgee") {
    if (!rlang::is_installed("rgee")) {
      cli::cli_abort(c(
        "The {.pkg rgee} package is required for {.code backend = \"rgee\"}.",
        i = "Install with: {.code install.packages(\"rgee\")}",
        i = "Or use {.code backend = \"rest\"} (default, no Python needed)."
      ))
    }
  }
}


#' Check GEE connection status
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Reports the current state of the GEE connection: authentication
#' status, active backend, project ID, cache directory, and cache
#' size.
#'
#' @returns A list (invisibly) with components:
#' \describe{
#'   \item{authenticated}{Logical. Is a valid token available?}
#'   \item{project}{Character. Active GCP project ID.}
#'   \item{rgee_available}{Logical. Is rgee installed?}
#'   \item{cache_dir}{Character. Path to disk cache directory.}
#'   \item{cache_size}{Numeric. Cache size in MB.}
#'   \item{n_datasets}{Integer. Number of registered datasets.}
#' }
#'
#' @family authentication
#' @seealso [gee_auth()], [gee_setup()]
#'
#' @examplesIf interactive()
#' gee_status()
#'
#' @export
gee_status <- function() {
  token <- .gee_token()
  authed <- !is.null(token)

  rgee_avail <- rlang::is_installed("rgee")

  cache_dir <- .cache_dir()
  cache_exists <- dir.exists(cache_dir)
  cache_size <- 0
  if (cache_exists) {
    files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)
    cache_size <- sum(file.size(files), na.rm = TRUE) / 1e6
  }

  n_datasets <- length(.gee_combined_meta())

  # Print status report
  cli::cli_h2("geefetch status")

  if (authed) {
    cli::cli_alert_success("Authenticated: yes")
  } else {
    cli::cli_alert_danger("Authenticated: no")
    cli::cli_alert_info("Run {.code gee_auth()} to authenticate.")
  }

  cli::cli_alert_info("Project: {.val {(.gee_project())}}")
  cli::cli_alert_info("Backend: REST API (httr2 + gargle)")

  if (rgee_avail) {
    cli::cli_alert_success("rgee backend: available")
  } else {
    cli::cli_alert_info("rgee backend: not installed (optional)")
  }

  cli::cli_alert_info("Cache dir: {.path {cache_dir}}")
  if (cache_exists) {
    cli::cli_alert_info(
      "Cache size: {.val {round(cache_size, 1)}} MB"
    )
  } else {
    cli::cli_alert_info("Cache: not yet created (will be on first use)")
  }

  cli::cli_alert_info("Registered datasets: {.val {n_datasets}}")

  invisible(list(
    authenticated = authed,
    project = .gee_project(),
    rgee_available = rgee_avail,
    cache_dir = cache_dir,
    cache_size = cache_size,
    n_datasets = n_datasets
  ))
}


#' Guided first-time setup for GEE access
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Interactive setup wizard that checks prerequisites, guides the user
#' through Google Earth Engine registration and authentication, and
#' verifies the connection.
#'
#' @returns `NULL`, invisibly. Called for side effects (prints
#'   instructions and optionally initiates authentication).
#'
#' @family authentication
#' @seealso [gee_auth()], [gee_status()]
#'
#' @examplesIf interactive()
#' gee_setup()
#'
#' @export
gee_setup <- function() {
  cli::cli_h1("geefetch setup")
  cli::cli_text("")
  cli::cli_text(
    "Full walkthrough: {.code vignette(\"geefetch\")} \u00a7 Authentication."
  )
  cli::cli_text(
    "This wizard lists the same checklist in order; follow it once and you'll"
  )
  cli::cli_text(
    "avoid the common HTTP 403 pitfalls."
  )
  cli::cli_text("")

  # Step 1: Check R packages
  cli::cli_h2("Step 1: Check R dependencies")
  cli::cli_alert_success("{.pkg gargle}: installed")
  cli::cli_alert_success("{.pkg httr2}: installed")
  if (rlang::is_installed("rgee")) {
    cli::cli_alert_success("{.pkg rgee}: installed (optional advanced backend)")
  } else {
    cli::cli_alert_info("{.pkg rgee}: not installed (optional, not required)")
  }

  # Step 2: Pick one Google account and stick with it
  cli::cli_h2("Step 2: Pick one Google account")
  cli::cli_text(
    "Every subsequent step happens under the {.strong same} Google account --"
  )
  cli::cli_text(
    "project creation, Earth Engine registration, OAuth consent in R."
  )
  cli::cli_text(
    "Mismatched accounts are the #1 cause of the 403 error new users see."
  )
  cli::cli_text("")

  # Step 3: Create a Google Cloud project
  cli::cli_h2("Step 3: Create a Google Cloud project")
  cli::cli_text("Visit:")
  cli::cli_text("{.url https://console.cloud.google.com/projectcreate}")
  cli::cli_text(
    "Note both the Project {.strong ID} (string, e.g. {.val my-geefetch-dev})"
  )
  cli::cli_text(
    "and the Project {.strong number} (12 digits, e.g. {.val 565208131613})."
  )
  cli::cli_text(
    "{.strong Use the number in R} - it is unambiguous across accounts."
  )
  cli::cli_text("")

  # Step 4: Register the project with Earth Engine
  cli::cli_h2("Step 4: Register the project with Earth Engine (noncommercial)")
  cli::cli_text("Visit:")
  cli::cli_text("{.url https://code.earthengine.google.com/register}")
  cli::cli_text(
    "Select {.strong Academic} or {.strong Research}, pick your new project,"
  )
  cli::cli_text("complete the institution form. Approval is typically instant.")
  cli::cli_text("")

  # Step 5: Enable the Earth Engine API
  cli::cli_h2("Step 5: Enable the Earth Engine API")
  cli::cli_text("Visit:")
  cli::cli_text(
    "{.url https://console.cloud.google.com/apis/library/earthengine.googleapis.com}"
  )
  cli::cli_text(
    "Confirm the project picker (top-left) shows your project, click {.strong Enable}."
  )
  cli::cli_text(
    "Wait ~30 seconds for the enablement to propagate."
  )
  cli::cli_text("")

  # Step 6: Authenticate in R
  cli::cli_h2("Step 6: Authenticate in R")
  cli::cli_text(
    "Use the project {.strong number} and the matching {.arg email}:"
  )
  cli::cli_code(paste0(
    'gee_auth(\n',
    '  project = "565208131613",    # <-- your project NUMBER\n',
    '  email   = "you@gmail.com"    # <-- matching Google account\n',
    ')'
  ))
  cli::cli_text(
    "For non-interactive / CI use, pass a service-account JSON key:"
  )
  cli::cli_code(paste0(
    'gee_auth(\n',
    '  project = "565208131613",\n',
    '  path    = "path/to/service-account.json"\n',
    ')'
  ))

  # Step 7: Verify + persist
  cli::cli_h2("Step 7: Verify and persist")
  cli::cli_code("gee_status()")
  cli::cli_text(
    "The {.field Project} line must show your project {.strong number}."
  )
  cli::cli_text(
    "To avoid retyping it each session, add to your {.file .Rprofile}:"
  )
  cli::cli_code('options(geefetch.project = "565208131613")')

  cli::cli_text("")
  cli::cli_rule(left = "Troubleshooting HTTP 403")
  cli::cli_text(
    "If the 403 error mentions a {.strong different} project number than the"
  )
  cli::cli_text(
    "one you passed, gargle has a cached token whose quota project disagrees"
  )
  cli::cli_text(
    "with your resource project. Restart R, wipe the cache, re-auth:"
  )
  cli::cli_code(paste0(
    'unlink(list.files(gargle::gargle_oauth_cache(), full.names = TRUE))\n',
    '# restart R, then:\n',
    'gee_auth(project = "565208131613", email = "you@gmail.com")'
  ))

  invisible(NULL)
}
