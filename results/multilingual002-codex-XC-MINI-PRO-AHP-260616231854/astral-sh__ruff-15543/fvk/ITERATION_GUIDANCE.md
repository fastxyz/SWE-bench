# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by this FVK pass. The V1 change directly discharges the reported singleton case and the broader bare tuple family while preserving the existing replacement path for non-bare iterable forms.

## Trace to findings and obligations

- Keep V1: `FINDINGS.md` F1 is discharged by `PROOF_OBLIGATIONS.md` PO1.
- Keep the generalized branch: `FINDINGS.md` F2 is discharged by `PROOF_OBLIGATIONS.md` PO2.
- Do not broaden the edit: `FINDINGS.md` F3 and `PROOF_OBLIGATIONS.md` PO3 require preserving the old behavior for all non-bare iterables.
- Do not alter tests: `FINDINGS.md` F4 requires keeping test coverage until tests and K tooling can be run.

## Recommended future tests

Do not modify tests in this task. In a normal development environment, add or keep coverage for:

- `for e in x,: yield e` fixes to `yield from (x,)`.
- `for e in x, y: yield e` fixes to `yield from (x, y)`.
- `for e in (x,): yield e` remains `yield from (x,)` without double wrapping.
- A non-tuple iterable such as `for e in items: yield e` remains `yield from items`.

## Machine-check follow-up

Run the recorded commands in `PROOF_OBLIGATIONS.md` or `PROOF.md` when a K environment exists. Until `kprove` returns `#Top`, treat test-removal recommendations as none.
