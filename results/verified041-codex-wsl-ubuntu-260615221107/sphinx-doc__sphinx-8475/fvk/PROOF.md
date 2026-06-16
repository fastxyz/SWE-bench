# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## What Is Proved

For every modeled non-anchor linkcheck request decision:

- successful `HEAD` responses are classified from `HEAD` without using `GET`;
- `HEAD` `HTTPError` keeps the existing `GET` fallback;
- `HEAD` `TooManyRedirects` also uses `GET`;
- after fallback, the existing GET classification determines the result.

This is partial correctness of the request-decision branch. It does not prove
network termination, Requests internals, socket behavior, TLS behavior, or
integration timing.

## Machine-Check Commands To Run Later

```sh
cd fvk
kompile mini-linkcheck.k --backend haskell
kast --backend haskell linkcheck-spec.k
kprove linkcheck-spec.k
```

Expected result after machine-checking: `kprove` returns `#Top`.

## Constructed Proof Sketch

The K semantics has one top-level step:

`checkNoAnchor(H, G) => classifyHead(H, G)`

The HEAD classifier has four relevant cases.

1. `classifyHead(ok(true, C), G)` rewrites to `result(working, false)`.
   This discharges PO-02 for same-URL HEAD success.
2. `classifyHead(ok(false, C), G)` rewrites to `result(redirected(C), false)`.
   This discharges PO-02 for HEAD redirect success.
3. `classifyHead(httpError(S), G)` rewrites to `classifyGet(G)`.
   A second rewrite by the GET classifier discharges PO-03.
4. `classifyHead(tooManyRedirects, G)` rewrites to `classifyGet(G)`.
   A second rewrite by the GET classifier discharges PO-04 and PO-05.

The GET classifier rewrites each modeled GET outcome to the existing status:
same URL to `working`, changed URL to `redirected(C)`, HTTP 401 to
`workingUnauthorized`, HTTP 503 to `ignored503`, other HTTP status failures to
`broken`, and GET exceptions to `broken`.

The source-level correspondence for the new case is direct: the V1 catch tuple
`except (HTTPError, TooManyRedirects):` encloses the HEAD request and
`response.raise_for_status()`. Therefore a `TooManyRedirects` raised by HEAD is
caught before the outer `except Exception` can return `broken`, and execution
continues into the existing GET request and classification path.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` says exactly the intent in
`fvk/INTENT_SPEC.md`: HEAD `TooManyRedirects` gets GET fallback, successful HEAD
and existing HTTPError fallback are preserved, and GET failures after fallback
remain broken. `fvk/SPEC_AUDIT.md` marks all entries PASS. No claim is supported
only by current implementation behavior.

## Test Guidance

Do not delete tests from this constructed proof. Existing public tests around
HEAD redirects, GET fallback, SSL errors, headers, auth, anchors, and output
format remain integration coverage outside the abstract proof. A useful
follow-up test would mock or simulate `requests.head` raising
`TooManyRedirects` and assert that `requests.get` is attempted and its result is
reported.

## Residual Risk

The trusted base is the adequacy of the abstract request-outcome model, the
source correspondence between the model and `check_uri()`, and the future
machine check of the K artifacts. The FVK result supports keeping V1 unchanged,
but it is not a machine-checked proof until the emitted commands run and
`kprove` returns `#Top`.
