# FVK Findings

Status: constructed from public intent, source inspection, and proof
obligations. No tests, Python, or K tooling were run.

## F-001: Pre-V1 HEAD TooManyRedirects skipped GET fallback

- Classification: code bug, addressed by V1.
- Evidence: problem statement says `TooManyRedirects` caused the GET fallback to
  be ignored and the link to be reported as broken.
- Concrete input: non-anchor HTTP/HTTPS URI where `HEAD` raises
  `TooManyRedirects` and `GET` would return a successful or redirected response.
- Observed pre-V1: outer generic exception handler returned `broken` before
  `GET` was attempted.
- Expected: retry with `GET` and classify the result from `GET`.
- Related proof obligation: PO-04.
- V1 status: closed by catching `TooManyRedirects` in the same inner fallback
  handler as `HTTPError`.

## F-002: V1 satisfies the named issue path

- Classification: confirmation finding.
- Evidence: `repo/sphinx/builders/linkcheck.py` now imports `TooManyRedirects`
  and catches `(HTTPError, TooManyRedirects)` around the `HEAD` request and
  `raise_for_status()` call.
- Concrete input: same as F-001.
- Observed V1: control enters the inner fallback and evaluates the existing
  `GET` request/classification path.
- Expected: same.
- Related proof obligation: PO-04.
- Status: no additional source change required.

## F-003: Broader RequestException fallback is not justified

- Classification: rejected alternative.
- Evidence: the issue specifically names `TooManyRedirects`; public tests cover
  HTTPError fallback; no public evidence says connection failures, SSL errors,
  or timeouts should retry with GET.
- Concrete input: non-anchor URI where `HEAD` raises a connection or SSL error.
- Observed V1: outer generic exception handling reports broken.
- Expected from available intent: unchanged.
- Related proof obligations: PO-06 and PO-08.
- Status: no source change.

## F-004: GET TooManyRedirects should still be broken

- Classification: boundary case, not a code bug under this intent.
- Evidence: the issue describes sites that redirect-loop for `HEAD`; the desired
  remedy is trying `GET`.
- Concrete input: `HEAD` raises `TooManyRedirects`, and fallback `GET` also
  raises `TooManyRedirects`.
- Observed V1: `GET` exception reaches the existing outer exception handler and
  reports broken.
- Expected: broken, because the fallback operation also failed.
- Related proof obligation: PO-05.
- Status: no source change.

## F-005: Formal model abstracts external network and Requests internals

- Classification: proof capability boundary, not a code bug.
- Evidence: FVK was run in a no-execution environment; Requests/network behavior
  is external I/O rather than deterministic pure computation.
- Concrete input: any real URL with server-dependent redirect behavior.
- Observed model: uses symbolic request outcomes such as `ok`, `httpError`, and
  `tooManyRedirects`.
- Expected: adequate for the fallback-control property, but not a proof of
  Requests internals, network termination, or server behavior.
- Related proof obligations: PO-01 and PO-09.
- Status: document residual risk; keep integration tests.

## Proof-Derived Findings From `/verify`

No open proof-derived code bug remains. The constructed claims cover the public
intent slice: HEAD success, existing HEAD HTTPError fallback, and the new HEAD
TooManyRedirects fallback. The only residual obligations are machine-checking
the emitted K artifacts and keeping tests that exercise integration with real
Requests/server behavior.
