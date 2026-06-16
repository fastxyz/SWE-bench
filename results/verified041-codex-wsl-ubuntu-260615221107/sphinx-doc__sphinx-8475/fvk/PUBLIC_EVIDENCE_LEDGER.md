# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "fallback to GET requests when HEAD requests returns Too Many Redirects" | `HEAD` `TooManyRedirects` is in the fallback set. | Encoded in SPEC and claims. |
| E2 | prompt | "the GET fallback is ignored as the exception is of type `TooManyRedirects` and the link is reported as broken" | Pre-fix `broken` without `GET` is the bug and must not be preserved. | Finding F-001, obligation PO-04. |
| E3 | prompt | "URLs ... used to pass ... but are now failing as HEAD requests have been enforced" | Fallback should restore GET-based classification for HEAD-only redirect loops. | Encoded in SPEC and claims. |
| E4 | public test | `test_follows_redirects_on_HEAD` expects HEAD redirects to be followed and reported as redirected. | Successful HEAD behavior is a frame condition; do not force GET. | Obligation PO-02. |
| E5 | public test | `test_follows_redirects_on_GET` expects HEAD 405 then GET redirect to be reported as redirected. | Existing HTTPError fallback is a frame condition. | Obligation PO-03. |
| E6 | code/comment | "try a HEAD request first" and "retry with GET request if that fails, some servers don't like HEAD requests." | Implementation shape is HEAD then fallback GET for selected HEAD failures. | Used as model structure, not independent intent. |
