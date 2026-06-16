# FVK Proof

Status: constructed, not machine-checked. No commands in this file were run.

## Commands To Machine-Check Later

```sh
kompile fvk/mini-requests-proxy.k --backend haskell
kast --backend haskell fvk/requests-proxy-spec.k
kprove fvk/requests-proxy-spec.k
```

Expected result if the mini semantics and claims are accepted by K:

`#Top`

## Claim Summary

The proof establishes that `prepend_scheme_if_needed` preserves proxy userinfo
in the normalized proxy URL for all modeled parsed URLs in the intended domain.
It also establishes that unauthenticated proxies, scheme preservation, scheme
prepending, and the existing path/netloc swap behavior are unchanged.

The proof does not establish network success, TLS behavior, all real URL parser
edge cases, or total Requests integration. Those remain covered by ordinary
integration tests.

## Symbolic Execution: Authenticated, Existing Scheme

Initial modeled state:

`purl(SCHEME, AUTH, NETLOC, PATH, QUERY, FRAG)` where:

- `SCHEME != ""`
- `AUTH != ""`
- `NETLOC != ""`

Source correspondence:

- tuple unpack at `repo/requests/utils.py:966-967`
- `netloc = parsed.netloc` at `repo/requests/utils.py:973`

Steps:

1. `effectiveNetloc(NETLOC, PATH)` rewrites to `NETLOC` because `NETLOC != ""`.
2. `withAuth(AUTH, NETLOC)` rewrites to `AUTH + "@" + NETLOC` because
   `AUTH != ""`.
3. `effectiveScheme(SCHEME, NEW)` rewrites to `SCHEME` because `SCHEME != ""`.
4. The returned modeled URL is:

   `out(SCHEME, AUTH + "@" + NETLOC, PATH, QUERY, FRAG)`

This discharges PO-AUTH-PRESERVE and PO-SCHEME for schemeful authenticated
proxy URLs.

## Symbolic Execution: Authenticated, Missing Scheme

Initial modeled state:

`purl("", AUTH, NETLOC, PATH, QUERY, FRAG)` where:

- `AUTH != ""`
- `NETLOC != ""`

Steps:

1. `effectiveNetloc(NETLOC, PATH)` rewrites to `NETLOC`.
2. `withAuth(AUTH, NETLOC)` rewrites to `AUTH + "@" + NETLOC`.
3. `effectiveScheme("", NEW)` rewrites to `NEW`.
4. The returned modeled URL is:

   `out(NEW, AUTH + "@" + NETLOC, PATH, QUERY, FRAG)`

This discharges PO-AUTH-PRESERVE for the scheme-prepending behavior introduced
for proxy URLs missing a scheme.

## Symbolic Execution: No Auth

Initial modeled state:

`purl(SCHEME, "", NETLOC, PATH, QUERY, FRAG)` where `NETLOC != ""`.

Steps:

1. `effectiveNetloc(NETLOC, PATH)` rewrites to `NETLOC`.
2. `withAuth("", NETLOC)` rewrites to `NETLOC`.
3. Scheme handling proceeds independently.
4. The returned modeled URL has no inserted `@`.

This discharges PO-NO-AUTH-FRAME.

## Symbolic Execution: Path/Netloc Swap

Initial modeled state:

`purl(SCHEME, AUTH, "", PATH, QUERY, FRAG)`.

Steps:

1. `effectiveNetloc("", PATH)` rewrites to `PATH`.
2. `effectivePath("", PATH)` rewrites to `""`.
3. If `AUTH != ""`, `withAuth(AUTH, PATH)` rewrites to `AUTH + "@" + PATH`;
   otherwise it rewrites to `PATH`.

This preserves the source behavior at `repo/requests/utils.py:973-975` and
shows V1 composes after, rather than replacing, that compatibility rule.

## Adapter Composition

Source chain:

1. `HTTPAdapter.get_connection` selects a proxy and calls
   `prepend_scheme_if_needed(proxy, 'http')`
   (`repo/requests/adapters.py:302-305`).
2. It passes the normalized proxy URL to `proxy_manager_for`
   (`repo/requests/adapters.py:310`).
3. For HTTP proxies, `proxy_manager_for` calls `proxy_headers(proxy)`, and
   `proxy_headers` uses `get_auth_from_url(proxy)`
   (`repo/requests/adapters.py:193-196` and `373-393`).

Because PO-AUTH-PRESERVE leaves the normalized URL in the form
`scheme://auth@netloc...`, the existing consumer path can recover the proxy
credentials. The pre-V1 code failed this composition because the normalized URL
was `scheme://netloc...`.

## Adequacy Gate

The formal English obligations match the intent-only spec:

- Auth preservation is required by the issue and proxy docs.
- Scheme behavior is required by the helper docstring and Requests 2.27 history.
- No-auth and path-swap frame conditions preserve unrelated existing behavior.
- Redirect proxy rebuilding was audited but not added to the code because it is
  not required by the public issue and documented proxy URLs are schemeful.

No adequacy failure blocks keeping V1.

## Residual Risk

The proof is partial correctness over a mini string-component model. It is not
machine-checked and it abstracts real parser behavior. Keep tests that exercise
urllib3 parsing, stdlib URL parsing, adapter integration, redirects, environment
proxy handling, and network proxy behavior.

No test deletion is recommended.
