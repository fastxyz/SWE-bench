# FVK Findings

Status: no open code defect was found after auditing V1 against the stated
specification. V1 stands.

## FINDING-F1: Resolved Auth-Loss Regression

Classification: code bug, resolved by V1.

Evidence:

- Public issue: `benchmark/PROBLEM.md:100-113` says `auth` remains parsed but is
  lost from the `netloc` passed to `urlunparse`.
- Source before V1 would rebuild from `parsed.netloc` only; `urllib3.parse_url`
  stores userinfo separately from `netloc`.
- V1 source: `repo/requests/utils.py:977-978` reattaches `auth` before
  reconstruction.

Concrete input class:

`http://user:pwd@host:8080` parsed as
`scheme=http`, `auth=user:pwd`, `netloc=host:8080`.

Observed before V1:

`http://host:8080`, so `get_auth_from_url` later sees no proxy userinfo.

Expected:

`http://user:pwd@host:8080`, so the downstream proxy setup can derive
`Proxy-Authorization`.

Related proof obligations:

- PO-AUTH-PRESERVE
- PO-ADAPTER-CONSUMER

Disposition:

Resolved. No additional source edit is required.

## FINDING-F2: Redirect Proxy Rebuild Does Not Justify a V2 Source Expansion

Classification: rejected expansion, not a code bug for this issue.

Evidence:

- `repo/requests/sessions.py:291-297` rebuilds a `Proxy-Authorization` header
  from `new_proxies[scheme]`.
- Public docs at `repo/docs/user/advanced.rst:620-626` document proxy auth in
  schemeful URL form.
- Public docs at `repo/docs/user/advanced.rst:640` say proxy URLs must include
  the scheme.
- The issue's concrete investigation points to `prepend_scheme_if_needed`, not
  redirect rebuilding: `benchmark/PROBLEM.md:101-113`.

Potential alternative:

Normalize `new_proxies[scheme]` inside `rebuild_proxies` before
`get_auth_from_url`.

Reason rejected:

That change would broaden behavior for scheme-less proxy URLs in the redirect
header path without public issue evidence. For documented schemeful proxy URLs,
`get_auth_from_url` already has the scheme it needs. The verified issue path is
the adapter's normalized proxy URL passed to `proxy_headers`.

Related proof obligations:

- PO-ADAPTER-CONSUMER
- PO-COMPAT-REDIRECT-NO-CHANGE

Disposition:

No source edit.

## FINDING-F3: Formalization Boundary

Classification: proof capability boundary, not a code bug.

The FVK model abstracts `urllib3.parse_url`, `urlunparse`, and
`get_auth_from_url` into component-level string operations. This abstraction is
adequate for the reported defect because the public issue itself identifies the
relevant component mismatch: `auth` is parsed separately and `netloc` excludes
it. The proof does not attempt to prove all URL parsing behavior or network
status 200.

Related proof obligations:

- PO-DOMAIN
- PO-AUTH-PRESERVE

Disposition:

Acceptable boundary for this audit. Keep integration tests for real parser and
network interactions.

## FINDING-F4: Constructed, Not Machine-Checked

Classification: verification status.

No Python tests, Python snippets, `kompile`, `kast`, or `kprove` were executed.
The proof artifacts contain commands that should be run later in an environment
where execution is allowed.

Related proof obligations:

- All obligations.

Disposition:

The code decision does not depend on runtime results. Test removal is not
recommended unless the emitted K proof is machine-checked.
