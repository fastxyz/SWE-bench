# FVK Spec - axios__axios-5892

Status: constructed, not machine-checked.

## Scope

The verified unit is the Node HTTP adapter's `content-encoding` decompression decision in `repo/lib/adapters/http.js`, mirrored in `repo/dist/node/axios.cjs`. The model covers the observable decision to:

- leave the response stream and `content-encoding` header unchanged;
- delete `content-encoding` without adding a decoder for `HEAD` or `204`;
- add the gzip/compress unzip decoder and delete the header;
- add the deflate header transform plus unzip decoder and delete the header;
- add the Brotli decoder and delete the header when Brotli is supported.

The model does not prove zlib's decompression algorithms, Node stream behavior, redirect handling, progress events, or package source-map fidelity.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| I1 | `benchmark/PROBLEM.md` | "header['content-encoding'] in many forms: 'Gzip', 'GZIP', 'GZip'" | Supported `content-encoding` values must be matched case-insensitively. | Encoded in `norm(E)` and claims C-GZIP/C-DEFLATE/C-BR. |
| I2 | `benchmark/PROBLEM.md` | "`GZIP` ... is a reason why axios don't decompress content" | A gzip response whose value is non-lowercase must enter the same decompression path as `gzip`. | Encoded in C-GZIP and the V2 code expression. |
| I3 | Existing adapter code/comment | "if decompress disabled we should not decompress" | `config.decompress === false` preserves pass-through behavior. | Encoded in C-DECOMPRESS-FALSE. |
| I4 | Existing adapter code/comment | "if no content ... remove the header" for `HEAD` or `204` | `HEAD` and `204` must delete the header but must not add a decoder. | Encoded in C-HEAD and C-204. |
| I5 | Existing switch cases | `gzip`, `x-gzip`, `compress`, `x-compress`, `deflate`, `br` | The existing supported encoding set is preserved, but comparison is against normalized values. | Encoded in C-GZIP, C-DEFLATE, C-BR. |
| I6 | Default domain assumption | HTTP content-coding values are token-like; optional surrounding whitespace is not part of the token. | Normalize by string coercion, OWS trim, then lowercase. | Encoded in proof obligation O1 and V2 `.trim().toLowerCase()`. |
| I7 | `repo/package.json` | CommonJS package export uses `./dist/node/axios.cjs` | The published CommonJS Node build must mirror the adapter fix. | Encoded in proof obligation O6 and compatibility audit. |

## Contract

Let `norm(E)` mean the JavaScript adapter expression:

```js
String(E || '').trim().toLowerCase()
```

For any response with `content-encoding` header value `E`:

1. If `config.decompress === false`, no decoder is added and the header is not deleted by this block.
2. If the header is absent, no decoder is added.
3. If `method === 'HEAD'` or `statusCode === 204`, the header is deleted and no decoder is added.
4. Otherwise, if `norm(E)` is `gzip`, `x-gzip`, `compress`, or `x-compress`, one unzip decoder is added and the header is deleted.
5. Otherwise, if `norm(E)` is `deflate`, the zlib-header transform and one unzip decoder are added and the header is deleted.
6. Otherwise, if `norm(E)` is `br` and Brotli is supported, one Brotli decoder is added and the header is deleted.
7. Otherwise, no decoder is added and the header is not deleted by this switch.

## V2 Code Decision

V1 already lowercased the value. The FVK audit refined the normalization to trim before lowercasing:

```js
switch (String(res.headers['content-encoding'] || '').trim().toLowerCase()) {
```

This preserves all existing branch ordering: the `HEAD`/`204` header deletion still occurs before the switch, so those paths do not add a decoder after the header has been removed.
