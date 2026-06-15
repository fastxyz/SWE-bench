# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify a V2 source edit.

## Trace to findings and proof obligations

- Kept the `TypeError` catch because `fvk/FINDINGS.md` F1 identifies the reported defect as dictionary input leaking raw `TypeError`, and `fvk/PROOF_OBLIGATIONS.md` PO5 requires `dictInput` to produce `ValidationError`.
- Kept the `ValueError` catch because F2 and PO6 classify malformed conversion input as the same model-field conversion failure under the base `Field.to_python()` contract and adjacent numeric field behavior.
- Did not change the valid-value paths because F3 and PO1-PO4 show `None`, float context conversion, valid non-float conversion, and existing invalid string behavior are preserved by the V1 edit.
- Did not add a broader catch-all because PO7 explicitly preserves targeted scope: only the known `decimal.Decimal(value)` conversion failures become `ValidationError`; unrelated exception classes are not silently swallowed.
- Did not edit signatures, callers, or subclasses because F4 and PO8 found no public compatibility issue.

## Artifacts produced

Required benchmark artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK core and adequacy artifacts required by the kit:

- `fvk/mini-decimal-field.k`
- `fvk/decimal-field-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Execution

No tests, Python code, `kompile`, `kast`, or `kprove` were run. The FVK proof is constructed, not machine-checked, and the commands to check it later are recorded in `fvk/PROOF.md`.
