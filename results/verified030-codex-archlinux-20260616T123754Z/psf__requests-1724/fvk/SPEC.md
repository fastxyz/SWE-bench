# FVK Specification: Unicode HTTP Method Normalization

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

The verified unit is `PreparedRequest.prepare_method()` in
`repo/requests/models.py`, with call-path obligations for:

- `Request(...).prepare()`
- `Session.prepare_request(Request(...))`
- `requests.request()` / `Session.request()` before `HTTPAdapter.send()`

The observable is the prepared request method that reaches the adapter as
`request.method`.

## Intent Spec

For every in-domain HTTP method token supplied as either a native string or a
Python 2 unicode string, Requests must prepare the method as the uppercase
native string type before transport. In Python 2, native string means byte
string, not unicode. `method=u'POST'` must therefore behave like
`method='POST'` for the transport boundary and must not cause a byte request
body to be coerced through ASCII decoding.

The method domain is ASCII HTTP method tokens. This is a default-domain
assumption from the meaning of "HTTP method" plus the issue's concrete `POST`
example. Non-ASCII method names are not used to justify the fix.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| - | - | - | - | - |
| E-001 | prompt | "`method=u'POST'` ... produces a UnicodeDecodeError" | This is buggy behavior, not a preserved behavior. | Encoded in PO-001 and F-001. |
| E-002 | prompt | "`method='POST'` works fine" and the only change is `u'POST'` | Unicode and native-string spellings of the same ASCII method must be equivalent at send time. | Encoded in PO-001, PO-002. |
| E-003 | prompt | "`u'POST'` is infecting the header with unicode when it should be a string" | Python 2 prepared method must be native `str`, not unicode. | Encoded in PO-001. |
| E-004 | API/docstring | `Request` says `:param method: HTTP method to use.` | Method remains a normalized HTTP verb; uppercasing is preserved. | Encoded in PO-003. |
| E-005 | implementation/docs | `to_native_string()` returns native string type and is already used for prepared header names. | Use existing compatibility boundary for native conversion. | Encoded in PO-001, PO-005. |
| E-006 | implementation | `HTTPAdapter.send()` passes `request.method` to `conn.urlopen(...)`. | The prepared method is the transport boundary value. | Encoded in PO-002. |

## Formal Domain

Inputs:

- `method` is `None`, or
- `method` is a native string or Python 2 unicode string representing an ASCII
  HTTP method token and supporting `.upper()`.

Postconditions:

- If `method is None`, `PreparedRequest.method` remains `None`.
- If `method` is an in-domain token, `PreparedRequest.method` is
  `to_native_string(method.upper())`.
- On Python 2, if `method` is unicode and ASCII, the result is a native byte
  string containing the uppercase token.
- Repeated session-level `.upper()` calls do not change the final uppercase
  token because ASCII uppercasing is idempotent.

Frame conditions:

- No public signature changes.
- No request body, header dictionary, URL, cookie, auth, or hook behavior is
  changed by the method normalization proof.
- Existing uppercase semantics are preserved.

## K Artifacts

The formal core is in:

- `fvk/mini-python-requests-method.k`
- `fvk/requests-method-spec.k`

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-python-requests-method.k --backend haskell
kast --backend haskell fvk/requests-method-spec.k
kprove fvk/requests-method-spec.k
```
