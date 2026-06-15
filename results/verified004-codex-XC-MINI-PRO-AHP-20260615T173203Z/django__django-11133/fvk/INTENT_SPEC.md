# Intent Specification

Status: constructed from public issue text, public hints, Django source comments, and public in-repo documentation. Candidate implementation behavior is treated only as behavior to check.

## Intended Domain

The audited behavior is the regular `HttpResponse` body conversion path and the shared `HttpResponseBase.make_bytes()` helper for response body values. In-domain values include:

- `str` content, encoded with the response charset.
- `bytes` content, preserved as bytes.
- `memoryview` content representing raw binary data from a database `BinaryField`, converted as `bytes(memoryview_value)`.
- Existing iterable content, consumed as chunks unless it is one of the scalar body value types above.

`StreamingHttpResponse(memoryview(...))` as a top-level streaming iterator is outside the direct issue scope because the streaming API expects an iterable of chunks. A memoryview yielded as a chunk is in scope through `make_bytes()`.

## Required Behavior

I-001: `HttpResponse("My Content").content` must be `b"My Content"` under the default UTF-8 charset, preserving the existing string conversion behavior shown as correct in the issue.

I-002: `HttpResponse(b"My Content").content` must be `b"My Content"`, preserving the existing bytes conversion behavior shown as correct in the issue.

I-003: `HttpResponse(memoryview(b"My Content")).content` must be `b"My Content"`. More generally, for any memoryview payload `M`, regular response content must equal `bytes(M)`.

I-004: A top-level memoryview passed to `HttpResponse.content` must be treated as one scalar bytes-like body value, not as an iterable of chunks.

I-005: `HttpResponseBase.make_bytes(memoryview_payload)` must return `bytes(memoryview_payload)` so shared response conversion sites, including `HttpResponse.write()` and streaming chunks, do not encode the memoryview object's representation.

I-006: Existing `str`, `bytes`, and non-memoryview iterable chunk semantics should be preserved except where they directly conflict with I-003 through I-005.

I-007: No test files may be modified, and no tests, Python snippets, or K tools may be executed in this session.
