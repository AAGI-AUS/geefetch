# geefetch tests

## Layout

- `setup.R` — runs once before any test file. Sanitises auth env vars,
  sets `NO_INTERNET=true`, disables the disk cache, pins locale for
  snapshot stability.
- `helper-recapture.R` — gated recapture machinery for HTTP cassettes.
  Only fires when `RPKG_RECAPTURE=1` is set in the environment.
- `test-*.R` — testthat files.
- `test-backend_rest-http.R` — archetype-6a HTTP tests using
  `httptest2::with_mock_dir()`. Cassettes live under
  `computeFeatures-*/` subdirectories of this folder.

## Running

```r
devtools::test()                                   # everything
devtools::test(filter = "backend_rest-http")        # just the HTTP suite
```

All HTTP tests `skip_if_not(dir.exists(test_path(...)))` when their
cassette directory is missing — they degrade to skip rather than hit the
live API.

## Recapturing HTTP cassettes

HTTP cassettes must be cut against a live GEE project. This happens
once per endpoint behaviour change, not on every test run.

### One-time setup

1. Authenticate in R with a maintainer account:

    ```r
    library(geefetch)
    gee_auth()
    gee_setup()  # prompts for GCP project ID
    ```

2. Export the project ID and the recapture flag in the same R session
   that runs the capture:

    ```r
    Sys.setenv(
      GEEFETCH_RECAPTURE_PROJECT = "<your-gcp-project>",
      RPKG_RECAPTURE             = "1"
    )
    ```

3. Run the capture:

    ```r
    devtools::test(filter = "backend_rest-http")
    ```

4. Inspect the new cassettes under `tests/testthat/computeFeatures-*/`.
   The redactor in `helper-recapture.R` strips `Authorization` headers
   and replaces your real project ID with the placeholder
   `geefetch-test-project`. Grep each cassette for any remaining
   personally-identifiable material before committing:

    ```bash
    grep -r "your-real-project\|Bearer\|access_token" tests/testthat/computeFeatures-*/ && \
      echo "REDACTION FAILED — do not commit"
    ```

5. Commit the cassette directories.

### Cassette cadence

Recapture when:

- The GEE REST API schema changes.
- A new endpoint is added to `backend_rest.R`.
- An existing test's assertions change materially (e.g. new field
  introspected on the response).

Do not recapture to "refresh" cassettes — they are replay fixtures, not
live-response snapshots.

## Live-API tests (separate from this suite)

Live integration tests that hit the real GEE API are tracked in a
dedicated workflow (not yet shipped — planned) and guarded by
`Sys.getenv("GEE_LIVE") == "1"` at runtime. They never run in the
default `devtools::test()` invocation.
