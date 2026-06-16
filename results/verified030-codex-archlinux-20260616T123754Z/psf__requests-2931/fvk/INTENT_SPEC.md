# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the Requests request-preparation behavior implicated by
the issue:

- `RequestEncodingMixin._encode_params`
- `PreparedRequest.prepare_body`
- the `_encode_params` call inside `PreparedRequest.prepare_url`

The audited observable is the prepared request body or URL query string. No
tests, Python, or K tooling were executed.

## Intent-Derived Obligations

I1. A non-empty raw `bytes` value supplied as `data` is already a request body.
Requests must preserve it byte-for-byte during preparation, including bytes
that are not ASCII.

I2. Preparing a non-empty raw `bytes` body must not call `to_native_string` on
that body. On Python 3, that conversion decodes bytes using ASCII by default,
which is the reported failure mechanism.

I3. A dictionary or list of key/value pairs supplied as `data` remains
form-encoded. This preserves the documented `data` behavior and existing public
tests.

I4. A raw text string supplied as `data` remains a raw body with no automatic
form content type.

I5. A `bytes` value supplied as `params` is URL parameter text, not a request
body. It must still be converted to a native string before URL assembly so
`params=b"test=foo"` prepares `...?test=foo`.

I6. The fix must not change `to_native_string` globally because it is used by
methods, URLs, headers, auth, redirects, and URL errors.

## Domain Boundaries

D1. The proof targets non-empty bytes bodies, matching the issue reproduction.
Empty bytes bodies interact with the pre-existing `if data:` and `json`
truthiness behavior and are not changed by this fix.

D2. URL `bytes` params are specified only for ASCII-compatible bytes in this
pass because the existing public evidence covers `b"test=foo"`, and the
pre-existing conversion uses ASCII.

D3. Multipart file uploads, streamed bodies, and file-like bodies are frame
conditions. They are not the reported defect path.
