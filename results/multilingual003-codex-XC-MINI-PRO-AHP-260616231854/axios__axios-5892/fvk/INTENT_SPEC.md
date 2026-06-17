# Intent Spec

Status: constructed, not machine-checked.

1. The Node HTTP adapter must treat supported `content-encoding` values case-insensitively.
2. A response with `content-encoding: GZIP`, `Gzip`, or `GZip` must be decompressed the same way as `gzip`.
3. The fix must preserve `decompress: false`.
4. The fix must preserve the existing `HEAD` and `204` no-body behavior.
5. The fix must preserve the existing supported content-coding set unless public intent says otherwise.
6. The packaged CommonJS Node build must expose the same behavior as the source adapter.
7. Optional surrounding whitespace around a token is not semantically part of the content-coding value.
