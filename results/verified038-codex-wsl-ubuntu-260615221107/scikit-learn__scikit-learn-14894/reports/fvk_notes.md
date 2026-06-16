# FVK Notes

## Decision: keep V1 unchanged

The FVK audit supports keeping the V1 source change in
`repo/sklearn/svm/base.py` unchanged. `fvk/FINDINGS.md` records the original
crash as F-001 and marks it resolved by V1. The corresponding proof obligations
in `fvk/PROOF_OBLIGATIONS.md` are PO-INDPTR-TOTAL and PO-EMPTY-CSR: the new
expression uses the default unit-step `np.arange(n_class + 1)`, so `n_SV == 0`
cannot create a zero-step `arange`, and the resulting row pointer is the
required all-zero sequence.

## Decision: no zero-support special case

I kept the uniform formula rather than adding an `if n_SV == 0` branch. This is
justified by F-001 and by PO-NONREGRESSION: for `n_SV > 0`, the formula produces
the same row starts as the pre-fix expression intended; for `n_SV == 0`, it
produces the valid empty CSR row pointer.

## Decision: no Cython or libsvm_sparse change

I did not edit `repo/sklearn/svm/libsvm_sparse.pyx`. F-002 identifies the Cython
return shape as a proof side condition, and PO-DATA-LENGTH discharges it using
the wrapper's allocation of coefficient data from `SV_len` and the fitted
attribute shape contracts. The reported traceback localizes the defect to
Python-side `dual_coef_indptr` reconstruction, not to the Cython data copy.

## Decision: no public API or compatibility change

I made no compatibility-oriented source edits. F-003 and PO-FRAME show that V1
changes only the local `dual_coef_indptr` expression and keeps the explicit CSR
shape `(n_class, n_SV)`, estimator method signatures, and other fitted
attributes unchanged.

## Tests and execution

No tests, Python snippets, or K tooling were run. The FVK proof is constructed
only, as recorded in `fvk/PROOF.md`, and this benchmark forbids executing code or
modifying tests.
