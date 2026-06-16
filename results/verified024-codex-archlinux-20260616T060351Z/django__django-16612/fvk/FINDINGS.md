# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Summary

No new production-code defect was found during the FVK audit. V1 stands
unchanged because it discharges all proof obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## F-001: Query string dropped by legacy redirect construction

- Classification: code bug, resolved by V1.
- Public evidence: `benchmark/PROBLEM.md` reports
  `/admin/auth/foo?id=123 -> /admin/auth/foo/` as actual and
  `/admin/auth/foo/?id=123` as expected.
- Concrete input: `APPEND_SLASH=True`, captured admin `url="auth/foo"`,
  slash-appended `path_info` resolves, resolved view permits slash appending,
  `request.path="/admin/auth/foo"`, and `QUERY_STRING="id=123"`.
- Legacy observed behavior: `HttpResponsePermanentRedirect("%s/" %
  request.path)` constructs `/admin/auth/foo/`.
- Expected behavior: redirect to `/admin/auth/foo/?id=123`.
- Proof obligations: PO-001, PO-002, and PO-003.
- V1 status: resolved. `request.get_full_path(force_append_slash=True)` builds
  the path with the forced slash and then appends `?` plus the query string when
  present.

## F-002: Redirect gate preservation

- Classification: compatibility/control-flow audit, no code bug found.
- Public/code evidence: the existing branch checks `APPEND_SLASH`, the captured
  URL suffix, `resolve("%s/" % request.path_info, urlconf)`, and
  `should_append_slash`.
- Concrete non-redirect inputs:
  - `APPEND_SLASH=False`.
  - URL already ends with `/`.
  - Slash-appended path does not resolve.
  - Resolved view has `should_append_slash=False`.
- Expected behavior: `Http404`, not redirect.
- Proof obligations: PO-004 and PO-005.
- V1 status: confirmed. V1 changes only the redirect target expression inside
  the already-gated redirect branch.

## F-003: Formal model abstraction boundary

- Classification: proof capability / abstraction boundary, not a code bug.
- Evidence: `get_full_path()` delegates to `escape_uri_path()` and
  `iri_to_uri()`, and `catch_all_view()` delegates route success to
  `resolve()`.
- Impact: the FVK model abstracts encoding and URL resolution with total
  functions/predicates because the audited property is query preservation in the
  constructed redirect location.
- Proof obligations: PO-006.
- Status: acceptable for this audit. A full Django/Python/K model would be
  required to prove encoding internals or URL resolver semantics, but that is
  outside the issue's behavioral property.

## Proof-derived findings from verify

No proof-derived code bug was found. The proof did surface one residual process
condition: the proof is constructed, not machine-checked, so any test
redundancy recommendation remains conditional on later `kprove` execution.
