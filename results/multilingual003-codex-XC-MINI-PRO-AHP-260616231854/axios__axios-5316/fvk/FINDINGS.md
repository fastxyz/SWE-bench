# FINDINGS

Status: findings from FVK formalization and proof construction. No commands were executed.

## F1: Node 18 global `FormData` fell through to the unsupported-object error

Input:

`config.data = new global.FormData()` with at least one string field, in the Node HTTP adapter.

Observed before the fix:

The adapter only handled `utils.isFormData(data) && data.getHeaders`. Node 18 global `FormData` has no `getHeaders`, is not a Node stream, and is not a string/Buffer/ArrayBuffer, so it reached:

`Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream`

Expected:

The adapter should support Node 18 `FormData` by converting it into a Node-sendable multipart stream and applying boundary-bearing multipart headers.

Classification:

Code bug / self-declared unsupported in-domain input.

Status:

Resolved by V1 source changes and preserved in V2. Proof obligations PO1-PO4 cover this finding.

## F2: V1 did not cover the public CommonJS reproduction path

Input:

The issue's public reproduction starts with `const axios = require('axios')`.

Observed in V1:

`repo/package.json` maps the CommonJS package export to `repo/dist/node/axios.cjs`. V1 patched `repo/lib/adapters/http.js` and added `repo/lib/helpers/formDataToStream.js`, but `repo/dist/node/axios.cjs` still had the old branch:

`if (utils.isFormData(data) && utils.isFunction(data.getHeaders)) ... else if (data && !utils.isStream(data)) ... reject(...)`

Expected:

The CommonJS public entry point should observe the same fixed behavior as the source ESM path, especially because running the build is forbidden in this benchmark.

Classification:

Public compatibility gap / stale generated producer.

Status:

Resolved in V2 by manually mirroring the helper and adapter branch into `repo/dist/node/axios.cjs`. Proof obligation PO5 covers this finding.

## F3: Machine checking and runtime verification are intentionally unavailable

Input:

Any proof or runtime claim in this FVK pass.

Observed:

The benchmark forbids running tests, Node code, Python, `kompile`, or `kprove`.

Expected:

Artifacts must include exact intended commands and mark the proof constructed, not machine-checked.

Classification:

Proof capability / environment constraint, not a code bug.

Status:

Open by design. `fvk/PROOF.md` includes commands and labels the proof accordingly. No test deletion is recommended before machine checking.
