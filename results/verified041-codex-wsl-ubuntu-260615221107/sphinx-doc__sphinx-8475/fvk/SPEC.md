# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the non-anchor HTTP/HTTPS branch of
`CheckExternalLinksBuilder.check_thread().check_uri()` in
`repo/sphinx/builders/linkcheck.py`. That branch is the behavior named by the
issue: linkcheck tries `HEAD`, then may retry with `GET`.

The formal model abstracts external Requests/network behavior into symbolic
outcomes. It does not model sockets, real redirects, TLS, response streaming,
or Requests internals. This abstraction is property-complete for the audited
defect because the property is the control-flow decision "which HEAD failures
invoke GET?" and the final status classification from an abstract response or
exception.

## Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | Problem: "fallback to GET requests when HEAD requests returns Too Many Redirects" | `TooManyRedirects` from `HEAD` must enter the GET fallback path. |
| E2 | Problem: "the GET fallback is ignored as the exception is of type `TooManyRedirects` and the link is reported as broken" | Early broken status for this case is the legacy bug. |
| E3 | Problem: URLs "used to pass ... but are now failing as HEAD requests have been enforced" | GET classification must be restored for HEAD-only redirect loops. |
| E4 | Public test `test_follows_redirects_on_HEAD` | Successful HEAD redirects remain classified from HEAD; no forced GET. |
| E5 | Public test `test_follows_redirects_on_GET` | Existing HEAD HTTPError fallback to GET remains intact. |
| E6 | Code comments around the request branch | Implementation shape is HEAD first, GET fallback for selected failures. |

## Contract

For a non-anchor HTTP/HTTPS URI that is not ignored or cached:

1. `HEAD` success is classified from the HEAD response.
2. `HEAD` `HTTPError` is classified by retrying with `GET`.
3. `HEAD` `TooManyRedirects` is classified by retrying with `GET`.
4. Other HEAD exceptions remain broken unless public intent separately names
   them as fallback-worthy.
5. After fallback, the existing GET classification rules apply: same URL is
   working, changed URL is redirected, HTTP 401 is working/unauthorized, HTTP
   503 is ignored, and other GET failures are broken.

## Formal Artifacts

- `fvk/mini-linkcheck.k`: abstract K semantics for the request decision.
- `fvk/linkcheck-spec.k`: K claims for HEAD success, existing HTTPError
  fallback, and the new TooManyRedirects fallback.

Exact commands to run later, not executed here:

```sh
cd fvk
kompile mini-linkcheck.k --backend haskell
kast --backend haskell linkcheck-spec.k
kprove linkcheck-spec.k
```

Expected machine-check outcome after installing/running K: `kprove` returns
`#Top` for all claims.

## Adequacy Result

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent-only obligations in `fvk/INTENT_SPEC.md`. The audit in
`fvk/SPEC_AUDIT.md` marks every obligation as PASS, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API or output-shape
compatibility issue.
