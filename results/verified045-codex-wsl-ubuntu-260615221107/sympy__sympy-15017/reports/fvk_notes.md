# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level problem in the
audited behavior; it confirmed that the root cause is the empty-shape cached
size and that V1 fixes it uniformly.

## Trace to findings and obligations

- `fvk/FINDINGS.md` F1 identifies the pre-V1 defect: rank-0 scalar arrays stored
  `_loop_size = 0`, so `NDimArray.__len__` returned `0`. `fvk/PROOF_OBLIGATIONS.md`
  PO1 and PO3 show why the fix belongs in the cached size calculation rather
  than in an unrelated caller.
- F3 confirms the V1 source edit discharges the intended behavior: all four
  dense/sparse and mutable/immutable constructor paths now compute the shape
  product with empty-product identity `1`. This maps to PO1, PO2, PO3, and PO4.
- F2 marks the old public test expectation `len(rank_zero_array) == 0` as
  SUSPECT because it conflicts with the issue's public intent. PO6 records why
  that legacy assertion cannot justify reverting or special-casing V1.
- F4 and PO5 confirm that V1 does not alter public signatures, constructor
  signatures, dispatch shape, or return type. The only intended observable
  change is the scalar rank-0 length value.

## Changes made in this FVK pass

- Added the FVK evidence package under `fvk/`, including the required
  `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and
  `ITERATION_GUIDANCE.md`.
- Added the formal core required by the FVK docs:
  `mini-sympy-array.k`, `array-size-spec.k`, `INTENT_SPEC.md`,
  `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
  `SPEC_AUDIT.md`, and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Made no additional source edits beyond V1.

## Verification status

No tests, Python code, or K tooling were run. The proof is constructed, not
machine-checked. The emitted commands in `fvk/SPEC.md` and `fvk/PROOF.md` are
for later execution in an environment that has K available.
