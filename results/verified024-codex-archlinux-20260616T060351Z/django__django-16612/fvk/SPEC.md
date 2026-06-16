# SPEC: AdminSite.catch_all_view APPEND_SLASH Redirect

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

The audited unit is `AdminSite.catch_all_view(request, url)` in
`repo/django/contrib/admin/sites.py`, plus the redirect-location construction it
delegates to `request.get_full_path(force_append_slash=True)` in
`repo/django/http/request.py`.

The observable under audit is the redirect response location, or `Http404` when
the catch-all view must not redirect.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "AdminSite.catch_all_view() drops query string in redirects" | A redirect produced by the admin catch-all must preserve the request query string. | Encoded by O2 and O3. |
| E2 | prompt example | Provided URL `/admin/auth/foo?id=123`; expected redirect `/admin/auth/foo/?id=123`; actual redirect `/admin/auth/foo/`. | For a non-empty query, append the slash before `?query`, not after it and not by dropping it. | Encoded by O3. |
| E3 | prompt issue | "with settings.APPEND_SLASH = True" | The redirect obligation applies when `APPEND_SLASH` is true. | Encoded by O1. |
| E4 | prompt hint | "Using get_full_path() should fix the issue" and replacement with `request.get_full_path(force_append_slash=True)`. | The intended construction API is `get_full_path(force_append_slash=True)`, which preserves query strings while forcing the slash. | Encoded by O2 and O3. |
| E5 | source code | `resolve("%s/" % request.path_info, urlconf)` and `getattr(match.func, "should_append_slash", True)`. | A redirect is permitted only if the slash-appended path resolves and the matched view allows slash appending. | Encoded by O1 and O4 as implementation/control-flow obligations. |
| E6 | source code | `get_full_path()` calls `_get_full_path(self.path, force_append_slash)`, which adds `?` plus `QUERY_STRING` when present. | The helper's postcondition includes the encoded query string exactly when the query string is non-empty. | Encoded by O3. |

## Intent-Derived Specification

For any request whose admin catch-all receives a path lacking a trailing slash:

O1. If `settings.APPEND_SLASH` is true, the slash-appended `path_info` resolves,
and the resolved view's `should_append_slash` flag is true or absent, then
`catch_all_view()` returns `HttpResponsePermanentRedirect`.

O2. The redirect location is the request full path with exactly the forced
trailing slash applied to the path component.

O3. If `QUERY_STRING` is non-empty, the redirect location preserves it as the
query component after the forced slash. For the issue example, the expected
location is `/admin/auth/foo/?id=123`.

O4. If any redirect gate fails (`APPEND_SLASH` false, URL already ending in
slash, slash-appended path unresolved, or `should_append_slash` false),
`catch_all_view()` raises `Http404` rather than redirecting.

O5. The change must not alter the public method signature, the final catch-all
URL registration shape, or the `should_append_slash` compatibility contract.

## Domain and Assumptions

The proof models the request state relevant to this issue:

- `PATH`: `request.path`, the full URL path excluding the query string.
- `PATH_INFO`: abstracted through the boolean `SLASH_RESOLVES`, representing
  whether `resolve("%s/" % request.path_info, urlconf)` succeeds.
- `QUERY`: `request.META["QUERY_STRING"]`, possibly empty.
- `URL_ENDS_SLASH`: whether the regex-captured admin `url` already ends in `/`.
- `SHOULD_APPEND`: the resolved view's effective `should_append_slash` value,
  with absence modeled as true.

Default-domain assumptions:

- Django request path fields are internally consistent: when the captured admin
  `url` lacks a trailing slash, the corresponding request path is the path to
  receive the forced slash.
- `escape_uri_path()` and `iri_to_uri()` are abstracted as total encoding
  functions. This abstraction preserves the audited property: whether the query
  component is present and where it appears.
- Partial correctness is sufficient here. The modeled unit has no loops or
  recursion in the redirect path.

## Formal Artifacts

- `fvk/mini-django-admin.k` gives a minimal K-style transition system for the
  relevant branch structure and full-path construction.
- `fvk/admin-catch-all-spec.k` states the reachability claims:
  - `CATCH-REDIRECT-PRESERVES-QUERY`
  - `FULL-PATH-NONEMPTY-QUERY`
  - `FULL-PATH-EMPTY-QUERY`
  - `CATCH-NO-REDIRECT-WHEN-GATES-FAIL`

The formal paraphrase and adequacy checks are in:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## V1 Audit Verdict

V1 satisfies the intent-derived obligations. The old construction
`"%s/" % request.path` satisfied the slash part of O2 but violated O3 because
`request.path` excludes `QUERY_STRING`. V1 replaces that construction with
`request.get_full_path(force_append_slash=True)`, which discharges O2 and O3
without changing the gates in O1/O4 or the public compatibility obligation O5.
