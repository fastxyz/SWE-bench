# FVK Notes

## Decisions

V1 stands unchanged as V2. F-001 identifies the reported defect as an uncaught `OverflowError` on the complete-triple path, and PO-001 is discharged by the existing V1 edit that catches `OverflowError` alongside `ValueError`.

No additional source edit was made. F-002 and F-003 show that the valid-date path, the existing `ValueError` pseudo-ISO path, the all-empty path, the missing-component fallback, and the public method protocol are preserved. Those preservation findings are discharged by PO-002 through PO-006.

F-004 records the only remaining caveat: the FVK proof is constructed, not machine-checked. PO-007 handles that by emitting the `kompile`, `kast`, and `kprove` commands in `fvk/PROOF.md` and keeping test-removal guidance conditional on a future machine check.

## Alternatives considered

Catching `TypeError` was rejected because the public issue and request-data domain concern string date components from `GET` or `POST`, not arbitrary object values. Pre-validating or clamping numeric ranges was rejected because PO-001 only requires preventing overflow from escaping, and PO-002 preserves the existing invalid-date pseudo-ISO behavior. Returning `None` for overflow was rejected because it would merge invalid complete triples with empty input and violate F-002.

## Artifacts

The FVK package is under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`, plus the adequacy and formal-core files required by the FVK contract.

