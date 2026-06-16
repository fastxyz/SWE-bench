# FVK Specification: psf__requests-2317

Status: constructed from public issue text and source inspection; not
machine-checked.

## Scope

The verified unit is the method-normalization slice of
`requests.sessions.Session.request`. That is the public API path used by
`requests.request(method, url, ...)` and by direct `Session.request(...)` calls.

The audited observable is the prepared request method after this sequence:

1. `Session.request(method, url, ...)` normalizes `method`.
2. It constructs a `Request` with `method.upper()`.
3. `Session.prepare_request` passes that method into `PreparedRequest.prepare`.
4. `PreparedRequest.prepare_method` uppercases it again.

## Intent Spec

I1. On Python 3, an ASCII byte-string HTTP method such as `b'GET'` passed to
`Session.request` must be decoded to native method text, not converted with
Python's `str(bytes)` representation.

I2. The prepared method must be the uppercase native token, e.g. `GET`, not a
literal bytes representation such as `"b'GET'"` or `"B'GET'"`.

I3. Existing native string methods must keep their prior semantics: normalize to
the uppercase native token.

I4. The fix must not change public function signatures, return shapes, adapter
dispatch shape, or request option merging.

I5. The specified byte-method domain is ASCII HTTP method tokens. Non-ASCII
bytes and arbitrary method-like objects are outside this issue's public intent.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`builtin_str(method)` converts method from b'GET' to \"b'GET'\"" | Treat Python 3 `str(bytes)` output as the bug. | Encoded in PO-1, PO-3, and the legacy discriminator claim. |
| E2 | prompt | "When requests tries to use the method \"b'GET'\", it gets a 404 Not Found response." | The malformed method must not reach the prepared request. | Encoded in PO-3. |
| E3 | prompt | "Seems if requests handled the method value being a binary string, we wouldn't have any problem." | Accept byte-string methods on the session request path. | Encoded in PO-1. |
| E4 | public hint | "This should have been caught and replaced with `to_native_str`." | Use the native-string conversion helper, not `builtin_str`. | V1 code evidence satisfies this with local `to_native_string`. |
| E5 | source docs | `Session.request` documents `method` as "method for the new Request object." | Preserve the API path and ordinary string-method behavior. | Encoded in PO-2, PO-4. |
| E6 | source code | `to_native_string` returns native strings unchanged and decodes non-native strings using ASCII on Python 3. | Establishes the intended implementation mechanism. | Used as implementation evidence for proof steps, not as standalone intent. |

No in-repo public test was used as an oracle. The task forbids modifying tests,
and no test execution is available.

## Formal Model

The constructed K core is in:

- `fvk/mini-requests-method.k`
- `fvk/session-request-method-spec.k`

The model is intentionally minimal but property-complete for this defect. It
keeps the axis under test visible: native method text and Python bytes-repr text
are distinct observables (`prepared(T)` versus `preparedBytesRepr(T)`).

The main claims are:

- `sessionRequest(bytes(T)) => prepared(upperToken(T))`
- `sessionRequest(native(T)) => prepared(upperToken(T))`
- `legacySessionRequest(bytes(T)) => preparedBytesRepr(upperToken(T))`

The third claim is not a desired postcondition; it is a discriminator for the
pre-V1 `builtin_str` behavior described in the issue.

## Formal Spec English

FE1. For every ASCII HTTP method token `T`, if a caller passes byte-string
method `bytes(T)` to `Session.request`, the final prepared method is the native
uppercase token `upperToken(T)`.

FE2. For every ASCII HTTP method token `T`, if a caller passes native string
method `native(T)` to `Session.request`, the final prepared method is the native
uppercase token `upperToken(T)`.

FE3. A session request with a byte-string method never reaches the
`preparedBytesRepr` observable under the V1 semantics.

FE4. The legacy `builtin_str` path maps a byte-string method to
`preparedBytesRepr(upperToken(T))`, matching the issue's reported failure shape.

## Adequacy Audit

| Formal English | Intent coverage | Result |
| --- | --- | --- |
| FE1 | Matches I1 and I2 from E1-E4. | Pass |
| FE2 | Matches I3 and E5. | Pass |
| FE3 | Matches I2 and E2. | Pass |
| FE4 | Matches E1 as a pre-V1 discriminator only. | Pass; not used as desired behavior |

No required behavior is weaker than the public issue. The spec does not claim
direct `Request.prepare()` byte-method normalization because the issue and hint
identify the `Session.request` conversion, and direct preparation does not create
the reported `"b'GET'"` literal through `builtin_str(method)`.

## Public Compatibility Audit

Changed public symbols: none.

Changed source symbol behavior: `Session.request`'s internal normalization of
`method` now uses `to_native_string`; signature and return type are unchanged.

Public callsites:

- `requests.api.request` constructs a `Session` and calls
  `session.request(method=method, url=url, **kwargs)`. Covered by FE1-FE3.
- `Session.get/options/head/post/put/patch/delete` pass native string constants.
  Covered by FE2 and unchanged.

Subclass/override risk:

- `Session.request` is a public method that may be overridden externally, but V1
  did not change its signature or dispatch protocol.
- Adapters still receive `request.method` in the same field. The only changed
  value is the intended correction from bytes-repr text to native method text
  for byte input.

Compatibility result: pass.
