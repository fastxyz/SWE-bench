# FVK Specification

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

The audited unit is the implicit `Content-Type` selection inside
`FileResponse.set_headers()` in `repo/django/http/response.py`. The issue
reports:

```python
FileResponse(open("test.html.Z", "rb"))
FileResponse(open("test.html.br", "rb"))
```

The modeled observable is the value assigned to `self.headers["Content-Type"]`
when no explicit `content_type` argument is supplied.

Out of scope for this proof are byte streaming, `Content-Length`,
`Content-Disposition`, file seeking, and the explicit static-file behavior in
`django.views.static.serve()`.

## Intent Specification

1. For `FileResponse(open("test.html.br", "rb"))` with no explicit content
   type, the final `.br` suffix must control the response MIME type; the
   response must not be served as `text/html`.
2. For `FileResponse(open("test.html.Z", "rb"))` with no explicit content type,
   the final `.Z` suffix must control the response MIME type; the response must
   not be served as `text/html`.
3. Existing compressed-file behavior must be preserved: gzip, bzip2, and xz
   suffixes are served as compressed-file media types, and `Content-Encoding` is
   not set by `FileResponse`.
4. Existing non-compressed behavior must be preserved: explicit `content_type`
   wins; missing or unknown implicit content type falls back to
   `application/octet-stream`; otherwise the unencoded guessed content type is
   used.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Improper guessing of Mime Type for \"br\" and \"Z\" file types" | `.br` and `.Z` are in-domain suffix cases for `FileResponse`. | Encoded in O2, O3. |
| E2 | `benchmark/PROBLEM.md` | "`FileResponse(open('test.html.Z', 'rb'))`" and "`FileResponse(open('test.html.br', 'rb'))` set the content type as `text/html`" | `text/html` is the reported buggy output for these inputs and must not be preserved as the expected result. | Encoded in O2, O3; finding FVK-F1/FVK-F2. |
| E3 | `tests/responses/test_fileresponse.py` | Compressed responses use `application/gzip`, `application/x-bzip`, and `application/x-xz`, and lack `Content-Encoding`. | Compression encodings should be converted to compressed-file media types in `FileResponse`, not served as underlying uncompressed content with an encoding header. | Encoded in O1, O4, O5. |
| E4 | `repo/django/http/response.py` | Comment: "Encoding isn't set to prevent browsers from automatically uncompressing files." | The proof must preserve the no-`Content-Encoding` behavior for this branch. | Encoded in O5. |
| E5 | `repo/django/http/response.py` | `content_type or "application/octet-stream"` and explicit `content_type` handling in `HttpResponseBase`/`FileResponse`. | Existing explicit and fallback behavior is a frame condition. | Encoded in O6. |
| E6 | `repo/django/views/static.py` and `tests/view_tests/tests/test_static.py` | Static serving passes an explicit content type to `FileResponse` and separately sets `Content-Encoding` when `mimetypes` reports one. | Static serving is a distinct public behavior and is not evidence that `FileResponse(open(...))` should set `Content-Encoding`. | Compatibility finding FVK-F4. |

## Formal Contract

Let `guess_type(filename) = (guessed_type, encoding)` be the public Python
MIME-guessing input consumed by `FileResponse.set_headers()`.

O1. If `encoding` is in Django's compressed-file map, the implicit
`Content-Type` is the mapped compressed-file media type:

| Encoding | Content-Type |
| --- | --- |
| `br` | `application/x-brotli` |
| `bzip2` | `application/x-bzip` |
| `compress` | `application/x-compress` |
| `gzip` | `application/gzip` |
| `xz` | `application/x-xz` |

O2. For `test.html.br`, modeled as
`guess_type("test.html.br") = ("text/html", "br")`, the implicit
`Content-Type` is `application/x-brotli`.

O3. For `test.html.Z`, modeled as
`guess_type("test.html.Z") = ("text/html", "compress")`, the implicit
`Content-Type` is `application/x-compress`.

O4. Existing compressed suffixes remain mapped as before:
`gzip -> application/gzip`, `bzip2 -> application/x-bzip`, and
`xz -> application/x-xz`.

O5. The implicit `FileResponse` branch does not set `Content-Encoding`.

O6. If there is an explicit `content_type`, it remains the response
`Content-Type`. If there is no filename or no guessed type and no compressed
encoding, the fallback is `application/octet-stream`.

## Formal Core

The accompanying formal artifacts are:

- `fvk/mini-mime.k`: a minimal K fragment for the content-type selection
  function.
- `fvk/fileresponse-content-type-spec.k`: reachability claims for obligations
  O1-O6.

The model deliberately abstracts away file I/O and response streaming while
preserving the property under verification: the final `Content-Type` value and
whether `Content-Encoding` is emitted by this branch.

## Formal Specification English

The K claims say:

1. Calling the modeled content-type selector with no explicit content type,
   filename `test.html.br`, guessed type `text/html`, and encoding `br` reaches
   `application/x-brotli`.
2. Calling it with no explicit content type, filename `test.html.Z`, guessed
   type `text/html`, and encoding `compress` reaches
   `application/x-compress`.
3. Calling it with the existing compressed encodings reaches their existing
   compressed-file media types.
4. Calling it with an explicit content type reaches that explicit value.
5. Calling it with no filename, or no guessed type and no compressed encoding,
   reaches `application/octet-stream`.
6. Calling the modeled `fileResponseSetsContentEncoding` predicate for this
   implicit branch reaches `noContentEncoding`.

## Adequacy Audit

All formal-English claims above pass against the intent specification:

- Claims 1 and 2 directly discharge E1 and E2.
- Claim 3 preserves the public compressed-file behavior from E3.
- Claim 4 and Claim 5 preserve the frame conditions from E5.
- Claim 6 preserves E3 and E4.

No claim depends solely on V1's candidate output. The expected compressed media
types for `br` and `compress` are derived by extending the existing
compressed-encoding family in E3/E4 to the two suffixes named by E1.

## Public Compatibility Audit

No public function signature, method dispatch shape, return type, storage
format, or call protocol changed. V1 only extends an internal literal mapping
inside `FileResponse.set_headers()`.

Known public callsites of `FileResponse` remain compatible because callers still
pass the same arguments and receive the same response object type. The only
observable change is the intended `Content-Type` value for implicit `.br` and
`.Z` compressed filenames.
