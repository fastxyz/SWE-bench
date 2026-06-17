# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Applied in V2

- Keep V1's case-insensitive comparison.
- Refine V1 by trimming optional surrounding whitespace before lowercasing.
- Mirror the same expression in `repo/dist/node/axios.cjs`.

These decisions trace to findings F1-F3 and proof obligations O1-O6.

## Do Not Change In This Iteration

- Do not implement stacked `Content-Encoding` support. Finding F4 marks it as a separate, underspecified feature requiring ordered decoder-list semantics.
- Do not alter `decompress: false`, `HEAD`, `204`, unsupported encoding, or Brotli-unsupported behavior. These are frame conditions in O3, O4, and O7.
- Do not modify tests. The benchmark fixes production code only, and proof-based test removal is conditioned on a future machine check.

## Suggested Future Public Tests

- `content-encoding: GZIP` decompresses as gzip.
- `content-encoding: Gzip` decompresses as gzip.
- `content-encoding: GZip` decompresses as gzip.
- `content-encoding: " GZIP "` decompresses as gzip if a caller can surface surrounding whitespace through the Node response header object.
- `content-encoding: GZIP` with `decompress: false` remains encoded.
- `HEAD` or `204` with `content-encoding: GZIP` deletes the header but adds no decoder.

## Next FVK Step If Expanded

If stacked encodings become in-scope, write a new spec where `Content-Encoding` parses to an ordered list of content codings and proves decoder composition in reverse encoding order.
