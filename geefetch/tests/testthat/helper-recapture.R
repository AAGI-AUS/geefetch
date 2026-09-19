# Recapture helper — gated behind RPKG_RECAPTURE env var.
#
# This never runs in CI. It runs when a maintainer wants to (re)capture
# HTTP cassettes for test-backend_rest-http.R against the live GEE REST
# API.
#
# Usage (once, interactively):
#
#   1. Authenticate normally: `geefetch::gee_auth()` + `geefetch::gee_setup()`.
#   2. Export your GEE project ID:
#      `Sys.setenv(GEEFETCH_RECAPTURE_PROJECT = "your-gcp-project")`.
#   3. Run the capture: `Sys.setenv(RPKG_RECAPTURE = "1")`, then
#      `devtools::test(filter = "backend_rest-http")`.
#   4. Verify the new cassette dirs under tests/testthat/computeFeatures-*/.
#   5. Sanitise — `httptest2::set_redactor()` is invoked below to strip
#      Authorization headers and any user-specific project identifiers.
#   6. Commit the cassette directories.
#
# Live cassettes must NOT contain any real access token or Google Cloud
# project identifier. The redactor below enforces that, but a human review
# before commit is still expected.

recapture <- nzchar(Sys.getenv("RPKG_RECAPTURE")) &&
  requireNamespace("httptest2", quietly = TRUE)
if (recapture) {
  httptest2::set_redactor(function(response) {
    response <- httptest2::redact_headers(response, "Authorization")
    response <- httptest2::gsub_response(
      response,
      Sys.getenv("GEEFETCH_RECAPTURE_PROJECT", "REDACTED"),
      "ee-test"
    )
    response
  })

  # Unset NO_INTERNET so real calls succeed during capture.
  Sys.unsetenv("NO_INTERNET")

  # Install a real token for capture — overrides setup.R's fake stub.
  if (!is.null(geefetch::gee_status()$authenticated)) {
    assign(
      "token",
      gargle::token_fetch(),
      envir = asNamespace("geefetch")$.geefetch_env
    )
    assign(
      "project",
      Sys.getenv("GEEFETCH_RECAPTURE_PROJECT"),
      envir = asNamespace("geefetch")$.geefetch_env
    )
  }
}
