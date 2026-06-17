# Baseline Notes

## Root cause

The Node HTTP adapter decides whether to decompress a response by switching on `res.headers['content-encoding']`. Node normalizes response header names to lowercase, but it does not lowercase header values. The adapter compared the value directly against lowercase encodings such as `gzip`, `x-gzip`, `compress`, `deflate`, and `br`, so responses with values like `GZIP`, `Gzip`, or `GZip` skipped the decompression pipeline.

## Changed files

- `repo/lib/adapters/http.js`: lowercased the `content-encoding` value at the decompression switch so supported encodings are matched case-insensitively while preserving the existing header deletion and `decompress: false` behavior.
- `repo/dist/node/axios.cjs`: mirrored the same adapter change in the packaged Node CommonJS build, because package consumers using `require('axios')` are routed through this file.

## Assumptions and alternatives considered

- I assumed the intended fix is limited to case-insensitive matching of known `content-encoding` values, not broader support for comma-separated stacked encodings such as `gzip, br`.
- I considered changing `AxiosHeaders` normalization, but rejected that because header names are already handled case-insensitively and the bug is specifically the unnormalized header value.
- I considered restructuring the decompression block to store a normalized local variable, but rejected that to avoid changing the existing `HEAD` and `204` handling, where the header is deleted before the switch and no decompressor is added.
- I did not modify tests or run the test suite, as required by the benchmark instructions.
