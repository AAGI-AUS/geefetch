# Test setup — runs once per `devtools::test()` call, before any test file.
# Recipe 07 (HTTP testing) §"Auth in tests" + §"CI" — sanitise environment
# so (a) a developer with real GEE credentials in their env doesn't
# accidentally hit the live API during a normal test run, (b) the CI runner
# has no network access expectation, (c) the disk cache is off so tests
# don't poison or rely on a user cache directory.

# 1. Clear any GEE-related credentials that might leak from a developer's shell,
#    unless a maintainer has explicitly opted into the live integration suite
#    (test-live.R) via GEEFETCH_LIVE=1 — that suite needs GEEFETCH_PROJECT to
#    survive into the test file, and authenticates with its own guarded helper.
if (!identical(Sys.getenv("GEEFETCH_LIVE"), "1")) {
  Sys.unsetenv(c(
    "GOOGLE_APPLICATION_CREDENTIALS",
    "GEE_PROJECT_ID",
    "GEEFETCH_TOKEN",
    "GEEFETCH_PROJECT"
  ))
}

# 2. Declare "no internet" by default. Tests that intentionally hit the
#    live GEE API must unset this and guard with skip_if(Sys.getenv("GEE_LIVE")
#    != "1") or equivalent. GEEFETCH_LIVE=1 (test-live.R) is the same opt-in.
if (!identical(Sys.getenv("GEEFETCH_LIVE"), "1")) {
  Sys.setenv(NO_INTERNET = "true")
}

# 3. Disk caching is opt-in (see gee_cache_disk()) so it defaults to off
#    regardless of this block; the temp directory below is a defensive
#    redirect in case a test enables it without also setting its own
#    directory. Removed at the end of the test run so it doesn't linger.
#    Individual tests may re-enable disk caching via
#    withr::local_options(geefetch.cache.disk = TRUE).
.geefetch_test_cache_dir <- tempfile("geefetch-cache-")
withr::defer(
  unlink(.geefetch_test_cache_dir, recursive = TRUE),
  teardown_env()
)
options(
  geefetch.cache.disk = FALSE,
  geefetch.cache_dir  = .geefetch_test_cache_dir
)

# 4. Reproducibility — pin locale so cli snapshot output is stable across
#    reviewers and CI runners (UTF-8 collation in particular affects
#    {?s} pluralisation and quote characters).
tryCatch(
  Sys.setlocale("LC_ALL", "en_AU.UTF-8"),
  warning = function(w) {
    # Some CI runners don't have en_AU.UTF-8; fall back to C.UTF-8.
    tryCatch(
      Sys.setlocale("LC_ALL", "C.UTF-8"),
      warning = function(w) invisible()
    )
  }
)

# 5. httptest2 defaults — quieten cassette matching and disable debug logs
#    that would clutter testthat output. Loaded lazily so setup.R doesn't
#    fail if httptest2 is not installed (Suggests-only).
if (requireNamespace("httptest2", quietly = TRUE)) {
  options(
    httptest2.verbose = FALSE,
    httptest2.debug   = FALSE
  )
}

# 6. Short cassette paths. httptest2 names a mock file after the full
#    request URL, which for Earth Engine pushes tarball paths past the
#    100-byte limit CRAN enforces. Point the package at a short host while
#    replaying; recording (RPKG_RECAPTURE=1) keeps the real host and the
#    helper renames the files afterwards.
if (!nzchar(Sys.getenv("RPKG_RECAPTURE")) &&
    !identical(Sys.getenv("GEEFETCH_LIVE"), "1")) {
  options(geefetch.rest_base = "https://ee")
}
