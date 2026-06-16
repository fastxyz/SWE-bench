# Iteration Guidance

Status: V1 stands unchanged.

## Code guidance

No further production-code edit is justified by the FVK findings.

- Keep `ModelChoiceIteratorValue.__hash__()` as `return hash(self.value)` because it discharges F1 through PO2, PO3, PO4, and PO5.
- Do not replace the wrapper with the primitive prepared value because F3 and PO6 show that would discard `.instance`.
- Do not add `__bool__()` in this issue because F4 and PO7 show no public intent evidence for truthiness parity and a possible compatibility change for falsey valid values.
- Do not special-case unhashable wrapped values because F5 and PO8 classify that as a Python hash-table domain boundary.
- Do not attempt to compensate for deliberately asymmetric custom dictionary keys because F7 and PO10 classify that as outside the public issue evidence.

## Suggested tests for a normal development environment

These are suggestions only; no tests were added or run in this task.

- `hash(ModelChoiceIteratorValue(1, obj)) == hash(1)`.
- `ModelChoiceIteratorValue(1, obj) in {1: 'payload'}`.
- `{1: 'payload'}[ModelChoiceIteratorValue(1, obj)] == 'payload'`.
- Existing list membership with `[1, 2]` remains true for a wrapper around `1`.
- A wrapper around an unhashable value raises `TypeError` from `hash()`.

## Verification guidance

To move from constructed proof to machine-checked proof, run the commands recorded in `fvk/PROOF.md` in an environment with K installed. Until then, keep all tests and treat the proof as constructed, not machine-checked.
