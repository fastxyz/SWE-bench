# PROOF OBLIGATIONS

Status: constructed obligations, not machine-checked.

## PO1: Spec-compliant `FormData` recognition

Obligation:

For a Node 18 global `FormData`, `utils.isFormData(data)` and `isSpecCompliantForm(data)` are true, while `data.getHeaders` is absent. Therefore the adapter must select the spec-compliant branch before the generic unsupported-object branch.

Evidence:

Ledger E1/E2. Source branch in `repo/lib/adapters/http.js`; mirrored branch in `repo/dist/node/axios.cjs`.

Finding link:

F1.

Status:

Discharged by inspection and formal claim 1.

## PO2: Multipart stream conversion

Obligation:

`formDataToStream(form, headersHandler)` returns a Node stream for spec-compliant `FormData`, not a plain object. That stream must be acceptable to the adapter's later `utils.isStream(data)` and `data.pipe(req)` paths.

Evidence:

`repo/lib/helpers/formDataToStream.js` returns `new stream.PassThrough()`. The CJS mirror returns `new stream__default["default"].PassThrough()`.

Finding link:

F1.

Status:

Discharged by inspection and formal claim 1's `ok(StreamData, ...)` result.

## PO3: Multipart headers include a generated boundary

Obligation:

The converted stream must be paired with `Content-Type: multipart/form-data; boundary=<generated>` so user-provided `multipart/form-data` is not left boundary-less.

Evidence:

`computedHeaders['Content-Type'] = \`multipart/form-data; boundary=${boundary}\`` in source and CJS mirror.

Finding link:

F1.

Status:

Discharged by inspection and formal claim 1.

## PO4: Multipart length is set when finite

Obligation:

For string and Blob/File entries with finite sizes, the helper computes a finite multipart body length and sets `Content-Length`; otherwise it leaves the length unset instead of guessing.

Evidence:

`FormDataPart.contentLength`, `contentLength += boundaryBytes.byteLength + part.size`, `utils.toFiniteNumber(contentLength)`, and `Number.isFinite(contentLength)` guard.

Finding link:

F1.

Status:

Discharged for the Node 18 string-field reproduction and Blob/File values with finite sizes. For non-finite custom values, length omission is the intended fallback.

## PO5: Public CommonJS entry point is fixed

Obligation:

The issue reproduction's `require('axios')` path must not retain the old unsupported-object behavior in this no-build workspace.

Evidence:

`repo/package.json` maps CommonJS require to `./dist/node/axios.cjs`. V2 adds the same helper and branch there.

Finding link:

F2.

Status:

Discharged by V2 code edit and compatibility audit.

## PO6: Legacy `form-data` support remains unchanged

Obligation:

Existing `form-data` package objects with `getHeaders()` must continue to use the original package-provided headers and must not be routed through the spec-compliant encoder.

Evidence:

The `getHeaders()` branch remains first in both source and CJS bundle.

Finding link:

Frame condition from ledger E5.

Status:

Discharged by inspection and formal claim 2.

## PO7: Unsupported non-FormData objects still reject

Obligation:

The fix must not silently accept arbitrary unsupported objects.

Evidence:

The generic unsupported-object branch remains after the legacy and spec-compliant FormData branches.

Finding link:

Frame condition from the issue's narrow requested support.

Status:

Discharged by inspection and formal claim 3.
