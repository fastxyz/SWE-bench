# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | V1 status |
| --- | --- | --- | --- |
| PO-1 | In the anchor-enabled branch, ordinary HTTP errors must be classified before anchor parsing. | E-1, E-2, E-3 | Discharged by V1 `response.raise_for_status()` before `check_anchor()` and K claim `LC-HTTP-ERROR-FIRST`. |
| PO-2 | For 404/500-style responses with missing anchors, output must be HTTP error text, not `Anchor '<name>' not found`. | E-1, E-2, E-4 | Discharged by `HTTPError` catch returning `('broken', str(err), 0)`. |
| PO-3 | Existing special HTTP policies must be preserved for anchor-bearing links: 401 remains working, 503 remains ignored. | E-3, E-7 | Discharged by routing anchor GET responses through the existing `except HTTPError` block. |
| PO-4 | Successful responses with missing anchors must still report missing anchor. | E-5, E-8 | Discharged because V1 only inserts status validation before the existing parser call; successful statuses continue to `check_anchor()`. |
| PO-5 | Successful responses with found anchors must preserve working/redirected behavior. | E-5, code flow | Discharged because response URL comparison and redirect logic are unchanged. |
| PO-6 | The fix must not change public API, config names, output schema, or tests. | I-5 | Discharged by static compatibility audit; only an internal call was added. |

## Verification Conditions

VC-1. `statusHttpError` rewrites to `resultBrokenHttp` with `anchorChecks = 0`.

VC-2. `statusUnauthorized` rewrites to `resultWorkingUnauthorized` with `anchorChecks = 0`.

VC-3. `statusUnavailable` rewrites to `resultIgnoredHttp` with `anchorChecks = 0`.

VC-4. `statusOK, anchorMissing` rewrites to `resultBrokenAnchor` with `anchorChecks = 1`.

VC-5. `statusOK, anchorFound, sameUrl` rewrites to `resultWorking` with `anchorChecks = 1`.

VC-6. `statusOK, anchorFound, redirectedUrl` rewrites to `resultRedirected` with `anchorChecks = 1`.

The reduced model has no loops, recursion, arithmetic side conditions beyond `0 +Int 1`, or circularities.
