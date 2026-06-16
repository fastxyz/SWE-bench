# ITERATION_GUIDANCE.md

## Verdict

V1 stands unchanged. The FVK audit found that the edit is exactly the source
change needed to satisfy the shape-level sparse join obligations derived from
the public issue.

## Code Guidance

- Keep the V1 source edit in `repo/sympy/matrices/sparse.py`.
- Do not move the fix into a broad `_eval_row_join`/`_eval_col_join` refactor
  for this task. The issue discussion identifies that as a larger API design
  question, while PO8 favors a minimal release fix.
- Do not edit tests in this benchmark.

## Future Verification Guidance

- In an environment with K installed, run the commands in `PROOF.md`.
- Until `kprove` returns `#Top`, treat the proof as constructed rather than
  machine-checked and keep all tests.
- If expanding the proof beyond shape, add sparse entry maps to the model and
  prove the existing index-shift frame property. That is outside the reported
  defect because the public examples are empty matrices and assert shape.

## Suggested Public Tests for a Normal Development Branch

These are recommendations only; no test files were modified here.

- `SparseMatrix.hstack(*[SparseMatrix.zeros(0, n) for n in range(4)]).shape`
  should be `(0, 6)`.
- `SparseMatrix.vstack(*[SparseMatrix.zeros(n, 0) for n in range(4)]).shape`
  should be `(6, 0)`.
- `SparseMatrix.hstack(*[SparseMatrix.zeros(1, n) for n in range(4)]).shape`
  should remain `(1, 6)`.
