# Intent Spec

Status: constructed from public issue text and source inspection, not machine-checked.

## Required behavior

1. Axios' Node HTTP adapter must support request bodies that are instances of Node.js 18's global WHATWG `FormData`.
2. A Node 18 `FormData` request body must not be rejected with `Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream`.
3. For multipart `FormData`, the adapter must produce a Node-sendable body and set multipart headers including a boundary-bearing `Content-Type`.
4. Existing support for the legacy `form-data` package must be preserved.
5. The public reproduction uses `const axios = require('axios')`; therefore the CommonJS package entry point must observe the same fixed behavior as the source ESM path in this no-build benchmark workspace.

## Domain assumptions

Node 18 global `FormData` is modeled as a spec-compliant iterable object with `append`, `Symbol.toStringTag === 'FormData'`, and entries whose values are strings or Blob/File-like values. The proof is partial correctness: if the adapter reaches request-body preparation, the body classification and header transformation satisfy the obligations above.
