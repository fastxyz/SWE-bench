# Baseline Notes

## Root cause

The Node HTTP adapter only recognized the `form-data` package variant of `FormData`. That path checks `utils.isFormData(data)` and `data.getHeaders()`, then applies the package-provided multipart headers.

Node 18's global `FormData` is a spec-compliant WHATWG-style object. It is recognized by `utils.isFormData(data)`, but it does not expose `getHeaders()` and is not a Node stream, string, Buffer, or ArrayBuffer. Because the adapter had no branch for that form, it fell through to the generic unsupported object error:

`Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream`

## Changed files

`repo/lib/helpers/formDataToStream.js`

Added a focused helper that converts spec-compliant iterable `FormData` into a Node readable stream. The helper generates a multipart boundary, escapes part names and filenames, emits multipart headers and body bytes, streams Blob/File values through their Web stream when available, computes `Content-Length` when part sizes are finite, and returns the generated `Content-Type`/`Content-Length` headers to the caller.

`repo/lib/adapters/http.js`

Imported the new helper and added a branch after the existing `form-data` package handling. The legacy `getHeaders()` behavior remains first. Spec-compliant `FormData` is now converted into a stream and gets multipart headers before the adapter reaches the unsupported-data validation.

## Assumptions

The issue concerns Node 18's built-in `FormData`, which is iterable, has `append`, and exposes `Symbol.toStringTag === 'FormData'`. The new helper targets that spec-compliant shape rather than arbitrary objects that merely stringify as `[object FormData]`.

FormData entry values are assumed to be strings or Blob/File-like values, matching the platform `FormData` contract. If all values have finite sizes, the helper sets `Content-Length`; otherwise it leaves it unset and lets the request stream chunk normally.

Generated `dist/` bundles were not edited because the requested fix is in source files under `repo/`, and the benchmark instructions disallow running build steps.

No tests or project code were run because the task explicitly says this session has no execution environment and forbids running tests or code.

## Alternatives considered and rejected

Changing `utils.isFormData` alone would only make detection broader; it would not provide the multipart serialization and Node stream required by `http.request`.

Converting Node 18 `FormData` through the legacy `form-data` package would require rebuilding entries into a different implementation and could alter Blob/File handling. A direct encoder is more targeted and avoids changing existing package-backed `FormData` behavior.

Using Node's global `fetch`/`Request` internals to serialize the body was rejected because axios' HTTP adapter needs explicit Node streams and request headers, and relying on those internals would make the adapter behavior less direct.
