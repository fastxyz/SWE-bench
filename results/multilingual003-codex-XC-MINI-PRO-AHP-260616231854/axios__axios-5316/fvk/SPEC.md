# SPEC

Status: FVK constructed specification, not machine-checked. No tests, Node code, Python, or K tooling were executed.

## Scope

This FVK pass audits the request-body preparation path changed by the axios__axios-5316 fix:

- `repo/lib/adapters/http.js`
- `repo/lib/helpers/formDataToStream.js`
- `repo/dist/node/axios.cjs`, because public `require('axios')` resolves there in this workspace

Network I/O, redirects, cancellation, response handling, and browser/XHR behavior are outside the issue's intent and are modeled only as frame conditions.

## Intent-Only Contract

The public issue requires support for Node.js 18 global `FormData` as request data. For such data, the Node HTTP adapter must not reject with:

`Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream`

Instead, the adapter must transform the `FormData` into a Node-sendable body and provide a valid multipart content type with a generated boundary. Existing support for the legacy `form-data` package remains unchanged.

Because the issue reproduction uses `const axios = require('axios')`, the CommonJS bundle is part of the observable public behavior for this benchmark state.

## Evidence Ledger

The detailed evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: Node 18 global `FormData` is in-domain and the unsupported-data error is the symptom to remove.
- E3/E6: `require('axios')` uses `dist/node/axios.cjs`, so V1's source-only fix was not complete for the public reproduction.
- E4: Multipart request data requires a boundary-bearing `Content-Type`.
- E5: Legacy `form-data` package behavior is a frame condition to preserve.

## Formal Model

Formal core:

- `fvk/mini-js-formdata.k`
- `fvk/axios-formdata-spec.k`

The mini semantics abstracts data into these classes:

- `LegacyFormData(L)`: `form-data` package data with package headers.
- `SpecFormData(N)`: Node 18 / WHATWG-style iterable `FormData`.
- `StreamData`, `BufferData`, `StringData`: existing supported request bodies.
- `OtherObject`: still unsupported.

The modeled observable is `(result data class, headers)` after request-body preparation. Multipart byte contents are abstracted to `multipartLength(N)` and `multipartContentType`, because the issue requires support, stream conversion, and boundary-bearing headers rather than a specific boundary value.

## Claims

1. `SpecFormData(N)` claim:
   For every `N >= 0`, `adapter(SpecFormData(N), headers("multipart/form-data", 0))` reaches `ok(StreamData, headers("multipart/form-data; boundary=<generated>", N))`.

2. Legacy frame claim:
   For every `L >= 0`, `adapter(LegacyFormData(L), headers("multipart/form-data", 0))` reaches `ok(LegacyFormData(L), headers("legacy-form-data-headers", L))`.

3. Unsupported-object frame claim:
   `adapter(OtherObject, headers("", 0))` reaches the existing unsupported-data rejection.

## Adequacy

Adequacy files:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The adequacy audit passes after V2. The only V1 failure was public CJS compatibility: source imports were fixed, but `require('axios')` still used the stale generated Node bundle. V2 resolves that gap by mirroring the helper and branch in `repo/dist/node/axios.cjs`.
