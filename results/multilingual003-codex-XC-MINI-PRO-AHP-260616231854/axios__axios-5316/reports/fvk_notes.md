# FVK Notes

## Decision Summary

The FVK audit confirmed the V1 source-level approach for Node 18 global `FormData`, but found one incomplete public path: the issue reproduction uses `require('axios')`, and this repository maps CommonJS require to `repo/dist/node/axios.cjs`. Because the benchmark forbids running the build, I manually mirrored the source fix into that Node bundle.

## Decisions Traced to Findings and Proof Obligations

### Kept `repo/lib/helpers/formDataToStream.js`

Finding F1 identifies the root bug: Node 18 global `FormData` was in-domain but fell through to the unsupported-object error. PO1 requires recognizing spec-compliant `FormData`; PO2 requires converting it to a Node stream; PO3 requires boundary-bearing multipart headers; PO4 covers finite content length. The helper discharges those obligations by generating a boundary, constructing multipart part headers/body delimiters, returning a `PassThrough` stream, and setting `Content-Type` plus finite `Content-Length`.

### Kept the `repo/lib/adapters/http.js` branch order

PO6 requires preserving legacy `form-data` package support. The source adapter still checks `utils.isFormData(data) && utils.isFunction(data.getHeaders)` first, then handles spec-compliant `FormData`, then leaves the existing unsupported-object branch for unrelated objects. This also satisfies PO7.

### Added the fix to `repo/dist/node/axios.cjs`

Finding F2 showed V1 was incomplete for the public reproduction path. `package.json` routes `require('axios')` to `dist/node/axios.cjs`, and the V1 bundle still had only the legacy `getHeaders()` branch followed by the unsupported-object rejection. PO5 requires the CommonJS entry point to observe the same fix in this no-build workspace, so I mirrored the helper and branch into `dist/node/axios.cjs`.

### Left browser/XHR code unchanged

No finding or proof obligation required a browser change. The public issue is specific to Node.js 18 global `FormData` and the Node HTTP adapter. Browser FormData behavior is already handled by the XHR adapter, so changing browser bundles would exceed the evidence-backed scope.

### Did not run or modify tests

Finding F3 records the environment constraint: tests, Node code, Python, and K tooling must not be run. The proof is therefore labeled constructed, not machine-checked, and no test deletion is recommended.

## Artifact Trace

- `fvk/FINDINGS.md`: F1 confirms V1 source logic; F2 justifies the V2 CJS bundle edit; F3 records the no-execution constraint.
- `fvk/PROOF_OBLIGATIONS.md`: PO1-PO4 justify the source helper and adapter branch; PO5 justifies the CJS mirror; PO6-PO7 justify preserving legacy and unsupported-object behavior.
- `fvk/PROOF.md`: gives the constructed proof and exact unexecuted `kompile`/`kast`/`kprove` commands.
