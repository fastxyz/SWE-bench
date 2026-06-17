# FVK Notes

## Decisions

I kept the V1 source change unchanged. The decision is justified by F-001 and PO-001: the reported failure is the nullish `sourcesContent` case, and V1's `if (sourcesContent)` guard removes the indexed read on that path while preserving `_inputMap` creation.

I did not synthesize fallback source contents from `code`. F-003 and PO-004 justify this: with an input source map, the map's `sources` can name earlier original files, so attaching the currently transformed code would misrepresent source contents.

I kept the inner `i < sourcesContent.length` guard. F-002 and PO-002 show it preserves valid pairwise copying for present contents, while preventing reads beyond a shorter content array. The public issue does not require stronger behavior for malformed sparse arrays.

I did not edit public APIs, generated files, or test files. PO-003 and PO-005 show the change is framed to local constructor behavior and public-compatible.

## Residual risk

F-004 records the only residual hardening question: a present but malformed sparse `sourcesContent` array is outside the formal domain and outside the public issue's concrete evidence. I did not expand the production fix for that case because no public intent source requires it.

## Artifacts

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The formal and adequacy core required by the FVK docs is also present:

- `fvk/mini-ts-sourcemap.k`
- `fvk/source-map-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The proof is constructed, not machine-checked. No tests, project code, Python, `kompile`, or `kprove` were run.
