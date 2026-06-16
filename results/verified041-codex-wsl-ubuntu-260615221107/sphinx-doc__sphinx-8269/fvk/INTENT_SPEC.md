# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for the issue `sphinx-doc__sphinx-8269`. The target behavior is the HTTP(S) `linkcheck` path for a URI with a non-ignored fragment when `linkcheck_anchors` is true. The HTML parsing loop inside `check_anchor()` is abstracted to the input states `anchorFound` and `anchorMissing`; this abstraction preserves the property under audit because the issue is about the ordering between HTTP status classification and anchor parsing, not about HTML parsing correctness.

## Intent-Only Obligations

I-1. When an anchor-bearing HTTP(S) link is checked and the server returns an HTTP error status such as 404 or 500, linkcheck must report the HTTP error rather than `Anchor '<name>' not found`.

I-2. The output for an anchor-bearing HTTP error should match the non-anchor-checking behavior for the base URL: a `broken` status with the existing `HTTPError` text, except for existing policy exceptions such as 401 and 503.

I-3. Anchor validation remains enabled for successful HTTP responses when `linkcheck_anchors` is true. A successful response that lacks the requested anchor should still report `Anchor '<name>' not found`.

I-4. A successful response that contains the requested anchor should keep the existing working or redirected classification, including appending the original anchor to redirected URLs.

I-5. The fix should not change public configuration names, builder APIs, output file formats, or test files.

## Default-Domain Assumptions

- `requests.Response.raise_for_status()` is the existing Sphinx/requests mechanism for turning HTTP error status codes into `HTTPError`.
- HTTP status classification is meaningful before body-level anchor validation.
- The FVK proof is partial correctness over the modeled branch; it does not prove network termination, request retry termination, or parser completeness.
