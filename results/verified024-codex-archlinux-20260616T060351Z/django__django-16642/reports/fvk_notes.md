# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Decision: Keep V1's `.br` Mapping

V1 added:

```python
"br": "application/x-brotli"
```

This stands because FVK-F1 identifies `.br` as a resolved V0 code bug, and
PO-2 requires the `test.html.br` path to return `application/x-brotli` rather
than the underlying `text/html`. The formal claim `BR-FILERESPONSE` models that
case directly.

No additional code change is needed for this obligation.

## Decision: Keep V1's `.Z` / `compress` Mapping

V1 added:

```python
"compress": "application/x-compress"
```

This stands because FVK-F2 identifies `.Z` as a resolved V0 code bug, and PO-3
requires the `test.html.Z` path to return `application/x-compress` rather than
the underlying `text/html`. The formal claim `COMPRESS-FILERESPONSE` models
that case directly.

No additional code change is needed for this obligation.

## Decision: Do Not Refactor Existing Compressed Mappings

The existing `gzip`, `bzip2`, and `xz` entries were left untouched.

This is justified by FVK-F3 and PO-4: public tests already establish those
compressed-file media types, and V1 only extends the existing map with the two
missing members.

## Decision: Do Not Add `Content-Encoding` in `FileResponse`

V1 continues to avoid setting `Content-Encoding` in `FileResponse.set_headers()`.

This is justified by FVK-F3 and PO-5. Public response tests and the source
comment state that `FileResponse` avoids `Content-Encoding` so browsers do not
automatically decompress the served file. The formal claim
`NO-CONTENT-ENCODING` captures that frame condition.

## Decision: Do Not Modify `django.views.static`

No changes were made to `repo/django/views/static.py`.

This is justified by FVK-F4 and PO-8. Static-file serving passes an explicit
content type to `FileResponse` and separately sets `Content-Encoding`; public
static-view tests assert that behavior. The issue demonstrates direct
`FileResponse(open(...))` calls, so changing static serving would conflate two
different public contracts.

## Decision: Preserve Explicit and Fallback Behavior

No source changes were made to explicit `content_type`, missing filename, or
unknown MIME fallback behavior.

This is justified by PO-6. V1 changes only the compressed encoding map and
therefore preserves explicit content-type precedence and the
`application/octet-stream` fallback.

## Decision: No Further Source Edits After FVK

The audit concluded that V1 satisfies the public intent and proof obligations.
No V2 source edit was applied.

This conclusion is supported by:

- FVK-F1 / PO-2 for `.br`;
- FVK-F2 / PO-3 for `.Z`;
- FVK-F3 / PO-4 / PO-5 for existing compressed behavior;
- FVK-F4 / PO-8 for leaving static serving unchanged;
- PO-6 / PO-7 for preserving fallback behavior and public compatibility.

FVK-F5 remains as a verification-confidence limitation only: the proof is
constructed but not machine-checked because the task forbids running K tooling,
tests, Python, or project code.
