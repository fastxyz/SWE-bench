# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

## E-001: Reported failure

- Source: `benchmark/PROBLEM.md`
- Evidence: "ZeroDivisionError in _sparse_fit for SVM with empty
  support_vectors_"
- Semantic obligation: the sparse fit path must handle `n_SV == 0` without a
  `ZeroDivisionError`.
- Status: encoded by `SPEC.md` and `svm-sparse-fit-spec.k` as the
  `n_SV >= 0` domain, with an explicit empty-support-vector postcondition.

## E-002: Expected empty sparse coefficients

- Source: `benchmark/PROBLEM.md`
- Evidence: "No error is thrown and `self.dual_coef_ = sp.csr_matrix([])`"
- Semantic obligation: in the SVR empty-support-vector case, the sparse fit path
  constructs an empty sparse `dual_coef_` rather than raising.
- Status: encoded as `indptr == [0, 0]`, no indices, no data, and shape
  `(1, 0)` when `n_class == 1` and `n_SV == 0`.

## E-003: Public shape contract for SVR

- Source: `repo/sklearn/svm/classes.py`
- Evidence: SVR documents `dual_coef_ : array, shape = [1, n_SV]`.
- Semantic obligation: the sparse reconstruction must keep one row for SVR,
  including when `n_SV == 0`.
- Status: encoded as `shape == (n_class, n_SV)` with `n_class == 1` for
  regressors.

## E-004: Public shape contract for classifiers

- Source: `repo/sklearn/svm/classes.py`
- Evidence: SVC/NuSVC document `dual_coef_ : array, shape = [n_class-1, n_SV]`.
- Semantic obligation: the fix must preserve the row count for classifier sparse
  fits.
- Status: encoded as `n_class == len(classes_) - 1` in `SPEC.md`, relying on
  `BaseSVC._validate_targets` rejecting fewer than two classes.

## E-005: Sparse/dense parity in public tests

- Source: `repo/sklearn/svm/tests/test_sparse.py`
- Evidence: public tests compare `dense_svm.dual_coef_` to
  `sparse_svm.dual_coef_.toarray()` and assert that sparse `dual_coef_` is
  sparse.
- Semantic obligation: the sparse path should preserve sparse representation
  and the dense-compatible coefficient layout.
- Status: encoded as a frame and compatibility obligation; no test file was
  edited.

## E-006: Cython return shape

- Source: `repo/sklearn/svm/libsvm_sparse.pyx`
- Evidence: `sv_coef_data = np.empty((n_class-1)*SV_len, dtype=np.float64)` and
  `support_vectors_` is built with shape `(SV_len, n_features)`.
- Semantic obligation: after Python maps libsvm's class count to
  `_sparse_fit`'s row count, `dual_coef_data` has exactly `n_class * n_SV`
  entries.
- Status: used as an implementation-side proof side condition, not as public
  intent by itself.
