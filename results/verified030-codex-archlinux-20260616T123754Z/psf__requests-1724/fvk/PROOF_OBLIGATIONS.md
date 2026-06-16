# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Prepared method native-string postcondition

For every ASCII HTTP method token `M`:

- `PreparedRequest.prepare_method(Unicode(M))` on Python 2 sets
  `self.method` to `Native(upper(M))`.
- `PreparedRequest.prepare_method(Native(M))` on Python 2 sets
  `self.method` to `Native(upper(M))`.
- The prepared value is not `Unicode(...)` at the transport boundary.

Proven by V1 line:

```python
self.method = to_native_string(self.method.upper())
```

Findings traced: F-001.

## PO-002: Session and request construction paths reach PO-001

For every in-domain method token passed through `requests.request()`,
`Session.request()`, `Session.prepare_request()`, or `Request.prepare()`, the
final method assigned to the prepared object is produced by
`PreparedRequest.prepare_method()`.

Repeated session-level `.upper()` calls may occur before `prepare_method()`, but
ASCII uppercasing is idempotent:

```text
upper(upper(M)) = upper(M)
```

Therefore all construction paths produce `Native(upper(M))` on Python 2.

Findings traced: F-001.

## PO-003: Existing uppercase semantics are preserved

For every in-domain method token `M`, the value portion of
`PreparedRequest.method` remains `upper(M)`. The V1 fix changes the Python 2
type for unicode input at the boundary, not the normalized method spelling.

Findings traced: F-001.

## PO-004: ASCII domain side condition

`to_native_string()` uses ASCII by default. The proof is valid when the method
text is an ASCII HTTP method token. For non-ASCII unicode method text, the
public issue does not establish required behavior.

Findings traced: F-002.

## PO-005: Public compatibility

The fix must not change public signatures, request construction shape, or the
adapter API. It may only change the prepared method's Python 2 runtime type for
unicode ASCII methods from unicode to native `str`.

Findings traced: F-001, F-003.

