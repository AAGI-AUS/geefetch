# auth.R — Google Earth Engine authentication via gargle
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
#' Authenticates with GEE using Google OAuth via the [gargle] package.
#' This is the same authentication flow used by
#' [googlesheets4](https://googlesheets4.tidyverse.org/),
#' [googledrive](https://googledrive.tidyverse.org/), and
#' [bigrquery](https://bigrquery.r-dbi.org/) — no Python required.
#'
#' For non-interactive use (CI, servers), use a service account JSON
#' key file via `gee_auth(path = "service-account.json")`.
#'
#' @param email Character. Google account email for OAuth. Use `NA` to
#'   force interactive account selection, or `""` to suppress
#'   auto-selection. Default uses [gargle::gargle_oauth_email()].
#' @param path Character. Path to a service account JSON key file.
#'   Mutually exclusive with `email`.
#' @param project Character. Google Cloud project ID with Earth Engine
#'   API enabled. Default `"earthengine-legacy"` (the public project).
#'   Set to your own project for higher quotas.
#' @param scopes Character. OAuth scopes. Default includes Earth Engine
#'   and Cloud Platform scopes.
#' @param cache Character. Directory for OAuth token cache.
#'   Default: [gargle::gargle_oauth_cache()].
#'
#' @returns Invisibly returns the gargle token. Called for side effects.
#'
#' @section Service accounts:
#' For automated pipelines (CI, HPC), create a service account in
#' Google Cloud Console, enable the Earth Engine API, and download
#' the JSON key. Then authenticate with:
#' ```r
#' gee_auth(path = "path/to/service-account.json")
#' ```
#'
#' @family authentication
#' @seealso [gee_status()] to check authentication state,
#'   [gee_setup()] for guided first-time setup.
#'
#' @examplesIf interactive()
#' # Interactive OAuth (opens browser)
#' gee_auth()
#'
#' # Specify account
#' gee_auth(email = "me@@gmail.com")
#'
#' # Service account (CI / non-interactive)
#' gee_auth(path = "path/to/service-account.json")
#'
#' # Use your own GCP project for higher quotas
#' gee_auth(email = "me@@gmail.com", project = "my-gee-project")
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
        "i" = "Download a key from Google Cloud Console > IAM > Service Accounts."
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
      "i" = "Run {.code gee_setup()} for guided setup instructions.",
      "i" = "Or try {.code gee_auth(email = NA)} to force account selection."
    ))
  }

  # Store token and project in package environment
  .geefetch_env$token <- token
  .geefetch_env$project <- project %||%
    getOption("geefetch.project", .GEE_DEFAULT_PROJECT)

  cli::cli_inform(c(
    "v" = "GEE authentication successful.",
    "i" = "Project: {.val {(.geefetch_env$project)}}"
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
        "i" = "Run {.code gee_auth()} to authenticate.",
        "i" = "Run {.code gee_setup()} for first-time setup instructions."
      ))
    }
  } else if (backend == "rgee") {
    if (!rlang::is_installed("rgee")) {
      cli::cli_abort(c(
        "The {.pkg rgee} package is required for {.code backend = \"rgee\"}.",
        "i" = "Install with: {.code install.packages(\"rgee\")}",
        "i" = "Or use {.code backend = \"rest\"} (default, no Python needed)."
      ))
    }
  }
}


#' Check GEE connection status
#'
#' @description
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

  # Step 1: Check R packages
  cli::cli_h2("Step 1: Check R dependencies")
  cli::cli_alert_success("{.pkg gargle}: installed")
  cli::cli_alert_success("{.pkg httr2}: installed")
  if (rlang::is_installed("rgee")) {
    cli::cli_alert_success("{.pkg rgee}: installed (optional advanced backend)")
  } else {
    cli::cli_alert_info("{.pkg rgee}: not installed (optional, not required)")
  }

  # Step 2: GEE registration
  cli::cli_h2("Step 2: Google Earth Engine registration")
  cli::cli_text(
    "If you don't yet have a GEE account, register at:"
  )
  cli::cli_text("{.url https://signup.earthengine.google.com/}")
  cli::cli_text("")
  cli::cli_text(
    "You need a Google account with Earth Engine access enabled."
  )
  cli::cli_text("")

  # Step 3: Enable the Earth Engine API (REQUIRED)
  cli::cli_h2("Step 3: Enable the Earth Engine API (required)")
  cli::cli_text(
    "The Earth Engine API must be enabled on your Google Cloud project."
  )
  cli::cli_text(
    "After authenticating (Step 4), if you get a 403 error, visit:"
  )
  cli::cli_text(
    "{.url https://console.developers.google.com/apis/api/earthengine.googleapis.com/}"
  )
  cli::cli_text("Select your project and click {.strong Enable}.")
  cli::cli_text("Wait 2-3 minutes, then retry your extraction.")
  cli::cli_text("")
  cli::cli_text(
    "For higher quotas, create a dedicated project at:"
  )
  cli::cli_text("{.url https://console.cloud.google.com/}")
  cli::cli_text("Then pass the project ID:")
  cli::cli_code('gee_auth(project = "my-project-id")')

  # Step 4: Authenticate
  cli::cli_h2("Step 4: Authenticate")
  cli::cli_text("Run the following to authenticate:")
  cli::cli_code("gee_auth()")
  cli::cli_text("")
  cli::cli_text(
    "This opens a browser for Google OAuth (same as googlesheets4)."
  )
  cli::cli_text("For CI/servers, use a service account JSON key:")
  cli::cli_code('gee_auth(path = "service-account.json")')

  # Step 5: Verify
  cli::cli_h2("Step 5: Verify")
  cli::cli_text("After authenticating, check your setup with:")
  cli::cli_code("gee_status()")

  invisible(NULL)
}
