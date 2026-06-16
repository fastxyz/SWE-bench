# FVK Findings

Status: constructed, not machine-checked.

## Summary

The FVK audit confirms the V1 source change. No additional source-code defect
was found in the audited slice. The original issue is represented as a resolved
finding because the pre-fix behavior is the bug signal that the proof obligation
targets.

## F-001: Pre-fix sparse reconstruction is undefined for zero support vectors

- Classification: code bug, resolved by V1.
- Input: the public issue's sparse `SVR` fit where libsvm returns
  `support_vectors_.shape[0] == 0`.
- Observed before V1: `_sparse_fit` computed the `np.arange` step as
  `dual_coef_indices.size / n_class == 0 / 1 == 0`, causing
  `ZeroDivisionError`.
- Expected: no error; `dual_coef_` is an empty sparse coefficient matrix.
- Public evidence: E-001 and E-002.
- Proof obligations: PO-INDPTR-TOTAL, PO-EMPTY-CSR.
- Resolution: V1 computes row pointers as `np.arange(n_class + 1) * n_SV`, which
  has no zero-step operation and yields `[0, 0]` for SVR with `n_SV == 0`.

## F-002: CSR validity depends on libsvm data length matching the Python row count

- Classification: proof side condition, discharged by public source evidence.
- Input class: any sparse libsvm fit after `libsvm_sparse_train` returns.
- Risk if false: SciPy CSR construction would reject mismatched `data`,
  `indices`, and `indptr`, or encode the wrong coefficient layout.
- Public/source evidence: E-003, E-004, and E-006.
- Proof obligations: PO-DATA-LENGTH, PO-CSR-SHAPE.
- Resolution: the Cython wrapper allocates coefficient data from the libsvm row
  count times `SV_len`; Python maps regression/one-class to one row and
  classifiers to `len(classes_) - 1`, matching the documented fitted attribute
  shapes.

## F-003: Public compatibility remains unchanged

- Classification: compatibility finding, no action required.
- Input class: public callers using fitted sparse SVM estimators and reading
  `dual_coef_`, `support_vectors_`, or `coef_`.
- Observed in V1: only a local row-pointer expression changed.
- Expected: no public method signature or fitted-attribute shape change.
- Public evidence: E-003, E-004, and E-005.
- Proof obligations: PO-NONREGRESSION and PO-FRAME.
- Resolution: V1 preserves the explicit CSR shape `(n_class, n_SV)` and only
  changes how its row pointer is generated.

## Unresolved Findings

None in the audited slice.

## Tests

No tests were run and no test files were modified. The benchmark explicitly
forbids running code or tests in this session.
