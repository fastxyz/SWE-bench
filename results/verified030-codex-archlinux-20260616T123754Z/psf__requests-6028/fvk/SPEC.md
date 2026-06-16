# FVK Specification: psf__requests-6028

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited behavior is proxy URL normalization for authenticated proxies. The
primary source target is `requests.utils.prepend_scheme_if_needed`, with the
consumer path through `HTTPAdapter.get_connection` and `HTTPAdapter.proxy_headers`.

The proof models `urllib3.util.parse_url` abstractly as a parsed tuple:

`(scheme, auth, netloc, path, query, fragment)`

This is property-complete for the defect because the bug is specifically the
loss of the parsed `auth` field when rebuilding the URL authority.

## Intent-Only Spec

1. Authenticated proxy URLs that contain `user:password@host` must preserve that
   userinfo while Requests normalizes or prepends the proxy scheme.
2. Preserved proxy userinfo must remain in the normalized proxy URL consumed by
   `HTTPAdapter.proxy_headers`, so `Proxy-Authorization` can be derived.
3. Existing scheme behavior must remain unchanged: a present scheme is kept,
   and a missing scheme is filled with the requested default scheme.
4. Existing compatibility behavior for inputs whose parsed netloc is empty must
   remain unchanged: the helper swaps parsed `path` into `netloc`.
5. The public docs require proxy URLs to include a scheme, but Requests 2.27
   also deliberately improved parsing for proxy URLs missing a scheme; the spec
   therefore covers both already-schemed and helper-prepended proxy URLs.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md:6-14` | Authenticated proxy request returns 407 but expected 200. | Proxy authentication must be sent when credentials are configured. | Encoded by PO-AUTH-PRESERVE and PO-ADAPTER-CONSUMER. |
| E2 | `benchmark/PROBLEM.md:100-113` | `user:pwd` is lost from `netloc`; `auth` is still parsed; rejoining `auth` and `netloc` resolves. | Rebuilt URL authority must be `auth@netloc` when `auth` is present. | Encoded by PO-AUTH-PRESERVE. |
| E3 | `benchmark/PROBLEM.md:117-119` | `user:pwd` is lost during proxy parsing and results in 407. | Credential preservation is required, not only URL cosmetic equivalence. | Encoded by PO-ADAPTER-CONSUMER. |
| E4 | `repo/docs/user/advanced.rst:620-626` | Proxy basic auth uses `http://user:password@host/` syntax. | Userinfo in proxy URLs is a supported public configuration shape. | Encoded by PO-AUTH-PRESERVE. |
| E5 | `repo/docs/user/advanced.rst:640` | Proxy URLs must include the scheme. | Redirect proxy rebuilding for documented proxy URLs can rely on schemeful inputs. | Used by FINDING-F2 to reject an unjustified source expansion. |
| E6 | `repo/HISTORY.md:25-26` | Requests 2.27 improved proxy parsing for URLs missing a scheme. | Scheme prepending remains in scope for the helper. | Encoded by PO-SCHEME and PO-PATH-SWAP. |
| E7 | `repo/requests/adapters.py:304-311` | `get_connection` calls `prepend_scheme_if_needed` before proxy manager creation. | The normalized URL is the value downstream proxy setup observes. | Encoded by PO-ADAPTER-CONSUMER. |
| E8 | `repo/requests/adapters.py:373-393` | `proxy_headers` extracts credentials from the proxy URL. | The normalized URL must still contain userinfo. | Encoded by PO-ADAPTER-CONSUMER. |

## Formal Contract Summary

Let `Parsed(url)` be the abstract parse result with fields:

- `scheme`: either a string scheme or empty for no scheme.
- `auth`: either empty or the original userinfo string.
- `netloc`: either empty or the host/port authority excluding auth.
- `path`, `query`, `fragment`: the remaining URL components.

Let `Normalize(url, new_scheme)` be the behavior of
`prepend_scheme_if_needed(url, new_scheme)`.

### PO-AUTH-PRESERVE

For every parsed proxy URL with non-empty `auth` and non-empty effective
`netloc`, `Normalize` returns a URL whose authority is `auth + "@" + netloc`.

This is the V1 source line:

`repo/requests/utils.py:977-978`

### PO-NO-AUTH-FRAME

For every parsed proxy URL with empty `auth`, `Normalize` returns the same
authority it would have returned before V1. The V1 edit does not affect
unauthenticated proxy URLs.

### PO-SCHEME

If `scheme` is present, `Normalize` keeps it. If `scheme` is absent,
`Normalize` uses `new_scheme`. This restates the helper docstring at
`repo/requests/utils.py:960-964`.

### PO-PATH-SWAP

If parsed `netloc` is empty, the existing compatibility rule swaps `path` into
`netloc` before scheme handling and URL reconstruction. V1 must not disturb this
behavior.

### PO-ADAPTER-CONSUMER

When `HTTPAdapter.get_connection` receives a selected authenticated proxy URL,
it passes the normalized proxy URL to `proxy_manager_for`; for HTTP proxies that
path calls `proxy_headers`, which uses `get_auth_from_url` on the normalized URL.
Therefore PO-AUTH-PRESERVE is sufficient for `Proxy-Authorization` derivation on
the issue path.

## Compatibility Audit

No public function signature changed. No test file changed. The only production
edit is inside `prepend_scheme_if_needed` and affects only the reconstructed
netloc when `parse_url` has already exposed a non-empty `auth` field.

`SessionRedirectMixin.rebuild_proxies` was inspected because it also replaces
`Proxy-Authorization` on redirects. For documented proxy URLs with schemes,
`get_auth_from_url` already parses userinfo. For scheme-less redirect proxy URLs,
the public docs say proxy URLs must include the scheme, while the issue localizes
the regression to `prepend_scheme_if_needed`; expanding the patch there would be
implementation-derived rather than intent-derived.
