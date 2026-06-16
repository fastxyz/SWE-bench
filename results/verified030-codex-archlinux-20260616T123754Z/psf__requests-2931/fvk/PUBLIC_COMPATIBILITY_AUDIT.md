# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`RequestEncodingMixin._encode_params(data)`

- Public surface: private helper by naming convention, but reachable as a class
  attribute.
- V1 behavior for `bytes`: `to_native_string(data)`.
- V2 behavior for `bytes`: return `data` unchanged.
- Compatibility result: compatible for the body-preparation intent and safer
  for direct bytes use. URL callers that need native text are handled at the
  public URL assembly call site.

`PreparedRequest.prepare_url(url, params)`

- Public surface: method on `PreparedRequest`.
- V2 change: if `_encode_params(params)` returns bytes, convert those bytes to
  native text before joining the URL query.
- Compatibility result: preserves public evidence for `params=b"test=foo"`.

`PreparedRequest.prepare_body(data, files, json=None)`

- Public surface: method on `PreparedRequest`.
- V2 effective change: raw bytes bodies are preserved by `_encode_params`
  instead of a caller-local bypass.
- Compatibility result: preserves raw text, form data, file-like, multipart,
  stream, and content-type behavior on the audited branches.

## Public Callsite Search

Observed `_encode_params` callers in source:

- `PreparedRequest.prepare_url`
- `PreparedRequest.prepare_body`

Both are accounted for in V2. No subclass override or virtual dispatch signature
change is introduced.

## Producer/Consumer Shape

- Body producer remains `PreparedRequest.body`.
- URL producer remains `PreparedRequest.url`.
- Header producer remains `PreparedRequest.headers`.
- No public return type or method signature changes are introduced.
