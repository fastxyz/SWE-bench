# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO-001: Redirect branch eligibility

If `APPEND_SLASH=True`, the captured admin URL does not end in `/`, the
slash-appended `path_info` resolves, and the resolved view allows slash
appending, `catch_all_view()` must return a permanent redirect.

- Evidence: E3 and E5 in `fvk/SPEC.md`.
- Formal claim: `CATCH-REDIRECT-PRESERVES-QUERY`.
- Related findings: F-001.
- V1 result: discharged.

## PO-002: Forced slash belongs to the path component

The redirect location must append the missing slash to the request path
component.

- Evidence: E2 and E4 in `fvk/SPEC.md`.
- Formal claims: `CATCH-REDIRECT-PRESERVES-QUERY`,
  `FULL-PATH-NONEMPTY-QUERY`, and `FULL-PATH-EMPTY-QUERY`.
- Related findings: F-001.
- V1 result: discharged by `request.get_full_path(force_append_slash=True)`.

## PO-003: Query string preservation

For every non-empty query string, the redirect location must preserve the query
component after the forced slash.

- Evidence: E1, E2, E4, and E6 in `fvk/SPEC.md`.
- Concrete witness: `/admin/auth/foo?id=123` must redirect to
  `/admin/auth/foo/?id=123`.
- Formal claims: `CATCH-REDIRECT-PRESERVES-QUERY` and
  `FULL-PATH-NONEMPTY-QUERY`.
- Related findings: F-001.
- V1 result: discharged.

## PO-004: Empty-query behavior

When the query string is empty, the redirect location must be the forced-slash
path with no trailing `?`.

- Evidence: E4 and E6 in `fvk/SPEC.md`.
- Formal claim: `FULL-PATH-EMPTY-QUERY`.
- Related findings: none open.
- V1 result: discharged.

## PO-005: Non-redirect branches

If any redirect gate fails, `catch_all_view()` must raise `Http404` rather than
redirecting.

- Evidence: E5 in `fvk/SPEC.md`.
- Formal claim family: `CATCH-NO-REDIRECT-WHEN-GATES-FAIL-*`.
- Related findings: F-002.
- V1 result: discharged because V1 does not change these branch conditions.

## PO-006: Public compatibility

The fix must not change public signatures, URL registration shape, override
requirements, or the `should_append_slash` protocol.

- Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Formal support: frame condition in `CATCH-REDIRECT-PRESERVES-QUERY`.
- Related findings: F-002 and F-003.
- V1 result: discharged. Only the redirect target expression changed.

## PO-007: Adequacy gate

The formal claims must not be weaker than the public issue intent and must not
prove the old query-dropping behavior.

- Evidence: `fvk/INTENT_SPEC.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, and
  `fvk/SPEC_AUDIT.md`.
- Related findings: F-001.
- V1 result: discharged. The claims require query preservation for all
  non-empty query strings, not only the example query.
