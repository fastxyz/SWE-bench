# FVK Spec

Status: constructed, not machine-checked.

Audited target: `repo/django/http/response.py`, specifically `HttpResponseBase.make_bytes()` and the `HttpResponse.content` setter.

## Public Intent Ledger Summary

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`.

- E-001 and E-002 require `HttpResponse(memoryview(b"...")).content` to expose the underlying bytes.
- E-003 requires string and bytes response behavior to remain unchanged.
- E-004 and E-005 require the conversion to be implemented as `bytes(memoryview_value)` in the shared response byte-conversion helper.
- E-006 shows Django's `force_bytes()` already treats memoryview as bytes-like.
- E-007 connects memoryview to raw binary `BinaryField` values.
- E-008 states the response body must be bytes.
- E-009 preserves the existing ordinary iterable chunk path.

## Intended Contract

For a regular `HttpResponse`, content assignment produces a one-element byte container for scalar body values:

- `bytes` is preserved as bytes.
- `str` is encoded with `self.charset`.
- `memoryview` is converted with `bytes(value)`.
- non-scalar iterables are consumed as chunks, each chunk is converted through `make_bytes()`, and the chunks are joined.

For `HttpResponseBase.make_bytes(value)`:

- if `value` is `bytes`, return `bytes(value)`;
- if `value` is `memoryview`, return `bytes(value)`;
- if `value` is `str`, return `bytes(value.encode(self.charset))`;
- otherwise return `str(value).encode(self.charset)`.

## Formal Claims

The K claims are in `http-response-spec.k`; the abstract semantics are in `mini-python-response.k`.

- `MAKE-BYTES-MEMORYVIEW`: `makeBytes(memoryView(P), C)` reaches `outBytes(P)`.
- `CONTENT-MEMORYVIEW`: `setContent(memoryView(P), C)` reaches a response container with `outBytes(P)`.
- `CONTENT-BYTES-FRAME`: `setContent(bytesValue(P), C)` reaches a response container with `outBytes(P)`.
- `CONTENT-STRING-FRAME`: `setContent(textValue(P), C)` reaches a response container with `encodedText(P, C)`.
- `CONTENT-ITERABLE-FRAME`: `setContent(iterableValue(CHUNKS), C)` reaches a response container with `joined(CHUNKS, C)`.

## Scope and Side Conditions

There are no loops in the audited code slice, so there are no loop circularities or termination proof obligations. The proof is partial correctness over the conversion branches: if the helper and setter return, they return the specified bytes/container values.

The model abstracts Python's actual `bytes(memoryview)` payload extraction as `memoryView(P) -> outBytes(P)`. That abstraction is independently anchored in the issue workaround and `force_bytes()` precedent.

Top-level `StreamingHttpResponse(memoryview(...))` is outside this spec because the streaming constructor accepts an iterable of chunks. A memoryview yielded as a chunk is covered by the `make_bytes()` claim.
