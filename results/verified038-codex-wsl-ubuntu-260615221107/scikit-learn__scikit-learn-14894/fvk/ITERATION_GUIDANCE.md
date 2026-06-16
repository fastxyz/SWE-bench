# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged. The FVK audit found that the one-line replacement:

```python
dual_coef_indptr = np.arange(n_class + 1) * n_SV
```

is total for `n_SV == 0`, preserves the intended row boundaries for
`n_SV > 0`, and keeps the public CSR shape contract.

## Recommended next actions

1. Keep the V1 source change in `repo/sklearn/svm/base.py`.
2. Do not add a special-case branch for `n_SV == 0`; the uniform formula is
   simpler and discharges both empty and non-empty obligations.
3. Do not edit Cython or libsvm wrapper code for this issue; the proof localizes
   the reported traceback to Python-side `indptr` reconstruction.
4. Add a regression test in normal development for the issue's sparse SVR
   reproducer, asserting that fit completes and `dual_coef_` is sparse with
   shape `(1, 0)`. This benchmark forbids modifying test files, so no test is
   added here.
5. If K tooling is available later, run the commands in `PROOF.md` before
   treating the proof as machine-checked.

## Residual risk

- The proof is constructed, not machine-checked.
- The mini semantics is scoped to the row-pointer expression and CSR shape
  arithmetic.
- Runtime behavior inside SciPy's CSR constructor and libsvm's optimizer is
  treated through their public/source-level shape contracts, not reverified.
