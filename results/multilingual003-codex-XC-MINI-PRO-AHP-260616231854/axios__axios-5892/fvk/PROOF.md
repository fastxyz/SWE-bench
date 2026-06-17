# FVK Proof

Status: constructed, not machine-checked.

## Claims Proved

The proof covers the reduced decision function specified in `fvk/http-encoding-spec.k` against the mini semantics in `fvk/mini-js-http-encoding.k`.

The key result is: for every in-scope response, the adapter's decompression decision is the same as the pre-existing lowercase behavior after applying `String(E || '').trim().toLowerCase()` to the header value. Therefore `GZIP`, `Gzip`, and `GZip` enter the gzip path, while the existing non-decode paths remain unchanged.

## Proof Sketch

1. Case split on `config.decompress !== false` and header presence.
2. If decompression is disabled or the header is absent, the outer guard is false and the decision is pass-through. This discharges O3.
3. If the guard is true, case split on the no-content paths. `HEAD` and `204` delete the header before the switch. The switch then sees an absent/empty value and adds no decoder. This discharges O4.
4. For all remaining responses, symbolic execution reaches `dispatch(norm(E), brotliSupported)`.
5. If `norm(E)` is `gzip`, `x-gzip`, `compress`, or `x-compress`, `dispatch` rewrites to `unzipAndDropEncoding`. This matches the adapter body that pushes `zlib.createUnzip(zlibOptions)` and deletes the header. This discharges O2 and O5 for gzip/compress.
6. If `norm(E)` is `deflate`, `dispatch` rewrites to `deflateAndDropEncoding`. This matches the adapter body that pushes `ZlibHeaderTransformStream`, then `createUnzip`, then deletes the header. This discharges O5 for deflate.
7. If `norm(E)` is `br` and Brotli is supported, `dispatch` rewrites to `brotliAndDropEncoding`; otherwise it rewrites to `passThrough`. This preserves the existing `isBrotliSupported` guard.
8. If no supported normalized encoding matches, the `owise` dispatch rule rewrites to `passThrough`. This discharges O7.

## Adequacy

The mini semantics abstracts the JavaScript expression `String(E || '').trim().toLowerCase()` as `norm(E)`. Proof obligation O1 connects that abstraction to the production code. The artifacts do not prove the ECMAScript built-ins, zlib, Node streams, or the full `httpAdapter`; they prove the branch decision used by the patch.

## Exact Commands To Machine-Check Later

These commands are not run in this session.

```sh
cd fvk
kompile mini-js-http-encoding.k --backend haskell
kast --backend haskell http-encoding-spec.k
kprove http-encoding-spec.k
```

Expected result after a successful machine check: `#Top`.

## Test Recommendation

Do not delete tests based on this constructed proof. After machine-checking, point tests for `GZIP`, `Gzip`, `GZip`, and mixed-case supported encodings would be subsumed by the normalized dispatch claims, but integration tests for actual Node streams, zlib errors, redirects, and response buffering should remain.

## Residual Risk

The proof is partial and scoped to the decision logic. Termination is immediate in the model because it contains no loops. Runtime stream behavior, source-map consistency, and stacked content encodings remain outside the proof.
