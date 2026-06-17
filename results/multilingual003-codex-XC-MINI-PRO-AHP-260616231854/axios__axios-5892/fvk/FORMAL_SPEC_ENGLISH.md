# Formal Spec English

Status: constructed, not machine-checked.

- C-DECOMPRESS-FALSE: If decompression is disabled, the decision is pass-through regardless of method, status, Brotli support, or header value.
- C-ABSENT: If there is no `content-encoding` header, the decision is pass-through.
- C-HEAD: If the method is `HEAD` and the header exists, delete the header but add no decoder.
- C-204: If the status is `204` and the header exists, delete the header but add no decoder.
- C-GZIP: If the response can have a body and `norm(E)` is `gzip`, `x-gzip`, `compress`, or `x-compress`, add the unzip decoder and delete the header.
- C-DEFLATE: If the response can have a body and `norm(E)` is `deflate`, add the deflate header transform, then the unzip decoder, and delete the header.
- C-BR-SUPPORTED: If the response can have a body, `norm(E)` is `br`, and Brotli is supported, add the Brotli decoder and delete the header.
- C-BR-UNSUPPORTED: If `norm(E)` is `br` but Brotli is not supported, do not add a decoder.
- C-UNKNOWN: If the normalized value is not a supported encoding, do not add a decoder.
- C-NORM: `norm(E)` is the adapter expression `String(E || '').trim().toLowerCase()`.
