# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | prompt | "Linkcheck should report HTTP errors instead of Anchor not found" | HTTP error status must dominate anchor-missing diagnosis. | Encoded in `PO-1`, `LC-HTTP-ERROR-FIRST`. |
| E-2 | prompt | "even when the server replied with an error status code (e.g. 404, 500)" | The obligation applies to the family of ordinary HTTP errors, not only 404. | Encoded by `statusHttpError` abstraction. |
| E-3 | prompt | "Expected output: Same as when `linkcheck_anchors=False`" | Anchor-enabled path should use existing `HTTPError` handling for error status responses. | Encoded in `PO-2`, `PO-3`. |
| E-4 | prompt | Actual buggy output was `Anchor 'test' not found`; expected was `404 Client Error: Not Found for url: https://google.com/test.txt` | The fragment must not be part of the request URL used for the HTTP error message; `req_url` is classified before anchor parsing. | Encoded in `PO-2`. |
| E-5 | docs | `linkcheck_anchors`: "If true, check the validity of `#anchor`s in links." | Successful responses with anchors still require anchor validation. | Encoded in `PO-4`, `PO-5`. |
| E-6 | code | Non-anchor branch calls `response.raise_for_status()` after HEAD and GET. | Existing implementation policy for HTTP status classification uses `raise_for_status()`. | Used as implementation evidence, not independent intent. |
| E-7 | code | `except HTTPError` maps 401 to working, 503 to ignored, other HTTP errors to broken. | V1 should preserve existing status-code policy once the anchor branch raises `HTTPError`. | Encoded in `PO-3`. |
| E-8 | public tests | Existing tests assert `Anchor 'top' not found` and `Anchor 'does-not-exist' not found`. | These are compatible only for successful responses lacking anchors; they cannot veto E-1/E-3 for HTTP error responses. | Marked compatible, not suspect for successful-response cases. |
| E-9 | baseline notes | V1 inserted `response.raise_for_status()` before `check_anchor()`. | Candidate edit directly targets the status-before-anchor ordering. | Checked by `PO-1` and proof claim `LC-HTTP-ERROR-FIRST`. |
