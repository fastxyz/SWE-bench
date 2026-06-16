# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found no code defect beyond the issue V1
already addressed.

## Why No Code Edit Is Needed

- `F-001` is resolved by the sign-classification and sign-joining obligations
  `PO-SIGN`, `PO-STR`, `PO-LATEX`, and `PO-PRETTY`.
- `F-002` and `F-006` confirm that all issue-named matrix-add printer
  contributors are covered by V1.
- `F-003` marks argument order as underspecified by public intent, so preserving
  `expr.args` order is the right frame condition.
- `F-004` confirms the fallback for objects without `as_coeff_mmul()` is a
  compatibility-preserving choice, not a gap in the MatrixSymbol issue.
- `F-005` is an honesty caveat about the un-run proof tooling, not a source
  defect.

## Recommended Follow-Up Tests

Do not edit tests in this benchmark task. For a normal development branch, add
public tests for:

- `str(A - A*B - B)` containing subtraction signs and no `(-1)*` unit
  coefficients;
- `pretty(A - A*B - B)` containing no plus separator immediately before a
  negative matrix term;
- `latex(A - A*B - B)` containing no `-1 B` or `-1 A B` unit coefficient
  bodies;
- a positive-first matrix sum with a negative interior term.

## Machine-Check Follow-Up

When a K environment exists, run the commands recorded in `PROOF.md`. Until
then, the proof remains constructed, not machine-checked, and no test-removal
recommendation should be acted on.
