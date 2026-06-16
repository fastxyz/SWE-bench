# FVK Proof Obligations

Status: constructed, not machine-checked.

The formal core is represented by:

- `fvk/mini-requests-proxy.k`
- `fvk/requests-proxy-spec.k`

These files model only the URL component manipulation needed for the defect.
They deliberately do not model sockets, DNS, TLS, urllib3 connection pools, or
the full Python runtime.

## PO-DOMAIN

For the issue path, the input is an intended proxy URL string accepted by
`parse_url` and reconstructed by `urlunparse`. The relevant parsed components
are:

- `auth` is empty or a userinfo string.
- effective `netloc` is the host/port authority excluding auth.
- `scheme` is either present or filled from `new_scheme`.

This is a default-domain assumption plus public evidence from:

- `repo/docs/user/advanced.rst:620-626`
- `repo/HISTORY.md:25-26`
- `benchmark/PROBLEM.md:101-113`

Status: discharged for the modeled domain.

## PO-AUTH-PRESERVE

Formal statement:

For any parsed proxy URL where `auth != ""` and effective `netloc != ""`,
`prepend_scheme_if_needed` reconstructs the authority as:

`auth + "@" + effective_netloc`

Source step:

`repo/requests/utils.py:977-978`

K claim:

`requests-proxy-spec.k`, claim `AUTH-PRESERVE-EXISTING-SCHEME` and
`AUTH-PRESERVE-PREPENDED-SCHEME`.

Status: discharged by straight-line symbolic execution of the modeled helper.

## PO-NO-AUTH-FRAME

Formal statement:

For any parsed proxy URL where `auth == ""`, V1 does not change the normalized
authority. It remains the effective netloc computed by the pre-existing logic.

Source step:

`repo/requests/utils.py:977` branches false when `auth` is empty.

K claim:

`requests-proxy-spec.k`, claim `NO-AUTH-FRAME`.

Status: discharged by branch analysis.

## PO-SCHEME

Formal statement:

If parsed `scheme` is present, keep it. If parsed `scheme` is absent, use
`new_scheme`.

Source step:

`repo/requests/utils.py:980-981`

K claim:

Covered by both auth-preservation claims and the no-auth frame claim.

Status: discharged by branch analysis.

## PO-PATH-SWAP

Formal statement:

If parsed `netloc` is empty, use `path` as the effective netloc and clear the
path, preserving the pre-existing compatibility behavior.

Source step:

`repo/requests/utils.py:973-975`

K claim:

`requests-proxy-spec.k`, claim `PATH-SWAP-FRAME`.

Status: discharged by branch analysis. V1 does not edit this branch except to
reattach auth after the effective netloc is chosen.

## PO-ADAPTER-CONSUMER

Formal statement:

On the HTTP proxy path, `HTTPAdapter.get_connection` passes the normalized proxy
URL to the proxy manager, and the HTTP proxy manager setup calls
`proxy_headers(proxy)`. If the normalized proxy URL contains `auth@netloc`,
`get_auth_from_url(proxy)` can produce credentials for `Proxy-Authorization`.

Source steps:

- `repo/requests/adapters.py:304-311`
- `repo/requests/adapters.py:373-393`

Status: discharged as a source-level composition obligation. The K model proves
the string component that the consumer requires; the consumer's behavior is
already covered by existing source logic and public docs.

## PO-COMPAT-REDIRECT-NO-CHANGE

Formal statement:

Do not change `SessionRedirectMixin.rebuild_proxies` unless public intent
requires broadening redirect behavior. For schemeful proxy URLs documented by
Requests, `get_auth_from_url(new_proxies[scheme])` already receives a parseable
URL.

Source steps:

- `repo/requests/sessions.py:291-297`
- `repo/docs/user/advanced.rst:620-640`

Status: discharged as a compatibility obligation. This supports keeping V1
unchanged rather than adding a second normalization path.

## No Loop Obligations

The audited code path has no loops and no recursion. The proof is straight-line
partial correctness over branch cases. Termination is immediate for the modeled
helper because the source executes a fixed number of conditional assignments and
a return.
