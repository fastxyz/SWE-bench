# FVK Notes

The FVK audit confirmed the core V1 fix and made one small V2 refinement.

## Code decisions

- Kept V1's case-insensitive dispatch because finding F1 and proof obligations O1/O2 show the reported `GZIP`, `Gzip`, and `GZip` failures are exactly caused by switching on the raw header value.
- Changed V1 from `.toLowerCase()` to `.trim().toLowerCase()` in `repo/lib/adapters/http.js` because finding F2 and obligation O1 identify optional surrounding whitespace as part of token normalization, not part of the content-coding value.
- Mirrored the same `.trim().toLowerCase()` expression in `repo/dist/node/axios.cjs` because obligation O6 and compatibility audit C2 show CommonJS package users are routed through the built Node file.
- Left `decompress: false`, absent-header, `HEAD`, `204`, unsupported-encoding, and Brotli-unsupported behavior unchanged because finding F3 and obligations O3/O4/O7 classify them as frame conditions.
- Did not add stacked `Content-Encoding` support because finding F4 and obligation O8 mark comma-separated decoder composition as a separate underspecified feature, not part of this issue's public intent.

## Artifact decisions

- Wrote the requested artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.
- Also wrote the FVK adequacy and K core files required by the FVK docs: `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-js-http-encoding.k`, and `fvk/http-encoding-spec.k`.
- The proof is labeled constructed, not machine-checked. Per finding F5 and obligation O9, I did not run K tooling, tests, Python, or project code.
