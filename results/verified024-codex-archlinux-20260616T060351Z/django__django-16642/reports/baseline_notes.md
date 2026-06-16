# Baseline Notes

## Root cause

`FileResponse.set_headers()` uses `mimetypes.guess_type()` to infer a file's
`Content-Type`. For filenames such as `test.html.Z` and `test.html.br`, Python
reports the underlying media type as `text/html` and the final suffix as a
compression encoding. Django already special-cased several compression
encodings so they are served as compressed files instead of as the underlying
uncompressed type, but the map did not include the encodings for `.Z`
(`compress`) or `.br` (`br`). As a result, those files inherited `text/html`.

## Changed files

`repo/django/http/response.py`

Added `br` and `compress` to the existing compression-encoding-to-content-type
mapping in `FileResponse.set_headers()`. This makes `.br` files use
`application/x-brotli` and `.Z` files use `application/x-compress`, while still
avoiding a `Content-Encoding` header so browsers do not automatically
decompress downloaded files.

## Assumptions and alternatives

I assumed the issue is specific to `FileResponse`'s implicit content type
guessing because the report demonstrates `FileResponse(open(...))`, and the
existing code already contains a targeted compressed-file MIME mapping for this
path.

I considered changing the generic static-file serving behavior in
`django.views.static`, but rejected that because it intentionally passes an
explicit `Content-Type` and sets `Content-Encoding` based on
`mimetypes.guess_type()`. That is a different serving model than
`FileResponse`'s download-oriented compressed-file handling.

I also considered stripping the final compressed suffix and defaulting all
encoded files to `application/octet-stream`, but rejected that because Django
already uses specific compressed-file media types for gzip, bzip2, and xz. The
smallest consistent fix is to extend that existing map for Brotli and Unix
compress files.

No tests or project code were run, per the task constraints.
