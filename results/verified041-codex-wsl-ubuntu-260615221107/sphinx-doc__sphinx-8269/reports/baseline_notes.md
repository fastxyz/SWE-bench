# Baseline Notes

## Root Cause

When `linkcheck_anchors` was enabled, `CheckExternalLinksBuilder.check_uri()` used a streamed GET request for links with fragments, then immediately parsed the response body with `check_anchor()`. That branch did not call `response.raise_for_status()` before parsing. As a result, an HTTP error response such as 404 or 500 could be treated as ordinary HTML content; if the requested fragment was absent from that error page, linkcheck reported `Anchor '<name>' not found` and masked the actual HTTP failure.

## Changed Files

- `repo/sphinx/builders/linkcheck.py`: added `response.raise_for_status()` in the anchor-checking GET path before scanning for the anchor. This makes links with fragments report HTTP errors through the existing `HTTPError` handling, while preserving anchor-not-found reporting for successful HTTP responses that simply lack the fragment.
- `reports/baseline_notes.md`: documented the diagnosis, source change, assumptions, and rejected alternatives for the benchmark task.

## Assumptions

- A successful HTTP status is required before anchor validation is meaningful. If the server returns an error status, that status should be the reported linkcheck failure even if the response body does not contain the requested anchor.
- The existing `HTTPError` handling remains the intended policy for status codes, including treating 401 as working and 503 as ignored.
- The issue is limited to HTTP(S) links checked through the anchor path; local files, ignored anchors, and links checked with `linkcheck_anchors = False` already bypass or validate through existing code paths.

## Alternatives Considered

- Checking the anchor first and then raising for status was rejected because it can still report an anchor problem for an HTTP error page, which is the behavior described in the issue.
- Reusing the non-anchor HEAD-then-GET flow for anchor links was rejected because anchor validation needs the response body. A single GET with status validation is the smallest change that keeps existing redirect and authentication behavior intact.
- Moving the status check into `check_anchor()` was rejected because `check_anchor()` is a body parser; keeping HTTP status handling in `check_uri()` preserves the current separation between request classification and anchor parsing.
