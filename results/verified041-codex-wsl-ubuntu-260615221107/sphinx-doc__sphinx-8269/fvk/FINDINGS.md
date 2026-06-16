# FVK Findings

Status: constructed, not machine-checked.

## Findings From Formalization

### F-1: Pre-V1 anchor branch masked HTTP errors

Input class: anchor-bearing HTTP(S) URI, `linkcheck_anchors = True`, server responds with ordinary HTTP error such as 404 or 500, requested anchor missing from the error page.

Observed in the issue: `broken ... Anchor '<anchor>' not found`.

Expected by public intent: `broken ... <HTTPError text>` for the base URL, same as the non-anchor-checking path.

Cause: the pre-V1 branch called `check_anchor(response, ...)` before any `response.raise_for_status()` call, so the parser could report a missing anchor from an HTTP error page.

V1 status: resolved. Proof obligations `PO-1` and `PO-2` are discharged by the inserted `response.raise_for_status()` before `check_anchor()`.

### F-2: Successful missing-anchor behavior must be preserved

Input class: anchor-bearing HTTP(S) URI, `linkcheck_anchors = True`, successful HTTP response, requested anchor absent.

Expected: `broken ... Anchor '<anchor>' not found`.

V1 status: preserved. `PO-4` is discharged because `raise_for_status()` is a no-op on successful responses, so the existing parser and missing-anchor exception still run.

### F-3: Special HTTP status policy must be preserved for anchor links

Input class: anchor-bearing HTTP(S) URI with HTTP status 401 or 503.

Expected: same policy as the existing `HTTPError` handler: 401 is working with unauthorized info; 503 is ignored.

V1 status: improved and preserved. `PO-3` is discharged because the anchor branch now reaches the existing `except HTTPError` policy instead of parsing the error body for anchors.

## Proof-Derived Findings From `/verify`

No open code bug was found after V1. The proof obligations cover the full intent slice described by the issue: status classification must happen before anchor parsing, while successful anchor checks keep their previous behavior.

Residual risk: the proof is constructed but not machine-checked, and it is scoped to the changed branch. It does not prove parser completeness, network behavior, or total correctness of worker threads.
