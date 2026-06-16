# Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## PO-1: Intent-Derived Domain

For implicit `FileResponse` content-type guessing, filenames ending in `.br`
and `.Z` are in domain.

Evidence: SPEC E1/E2.

Required result: these cases must not fall through to the underlying
`text/html` guessed type when the final suffix is a recognized compression
encoding.

Status: discharged by PO-2 and PO-3.

## PO-2: Brotli Encoding Mapping

Given no explicit content type and:

```text
filename = test.html.br
guess_type(filename) = (text/html, br)
```

the resulting `Content-Type` must be:

```text
application/x-brotli
```

Evidence: SPEC E1/E2 and the compressed-file family in E3/E4.

Status: discharged by V1's `"br": "application/x-brotli"` mapping and K claim
`BR-FILERESPONSE`.

## PO-3: Unix Compress Encoding Mapping

Given no explicit content type and:

```text
filename = test.html.Z
guess_type(filename) = (text/html, compress)
```

the resulting `Content-Type` must be:

```text
application/x-compress
```

Evidence: SPEC E1/E2, the compressed-file family in E3/E4, and the in-repo
public MIME evidence for `application/x-compress`.

Status: discharged by V1's `"compress": "application/x-compress"` mapping and
K claim `COMPRESS-FILERESPONSE`.

## PO-4: Existing Compressed Mappings Are Preserved

Given no explicit content type and an encoding already handled before V1, the
resulting `Content-Type` remains:

```text
gzip  -> application/gzip
bzip2 -> application/x-bzip
xz    -> application/x-xz
```

Evidence: SPEC E3/E4.

Status: discharged by unchanged map entries and K claims
`GZIP-PRESERVED`, `BZIP2-PRESERVED`, and `XZ-PRESERVED`.

## PO-5: No Content-Encoding Header in FileResponse Branch

The implicit compressed-file `FileResponse` branch must not set
`Content-Encoding`.

Evidence: SPEC E3/E4.

Status: discharged. V1 changes only the content-type mapping and does not add
any write to `self.headers["Content-Encoding"]`. K claim
`NO-CONTENT-ENCODING` models this observable as `noContentEncoding`.

## PO-6: Explicit and Fallback Behavior Are Preserved

If an explicit `content_type` is supplied, it remains the `Content-Type`.
If no filename or no guessed type and no mapped encoding exists, the result is
`application/octet-stream`.

Evidence: SPEC E5.

Status: discharged by unchanged control flow and K claims
`EXPLICIT-CONTENT-TYPE`, `NO-FILENAME-FALLBACK`, and `UNKNOWN-FALLBACK`.

## PO-7: No Public API Compatibility Break

The fix must not change public call signatures, return types, virtual dispatch
shape, or response object protocol.

Evidence: SPEC Public Compatibility Audit.

Status: discharged. V1 edits only a dictionary literal inside
`FileResponse.set_headers()`.

## PO-8: Static-File Serving Remains Out of Patch Scope

`django.views.static.serve()` intentionally passes an explicit content type and
sets `Content-Encoding` for encoded static files. The `FileResponse(open(...))`
fix must not change that contract.

Evidence: SPEC E6 and FINDINGS FVK-F4.

Status: discharged by leaving `repo/django/views/static.py` unchanged.
