# FVK Specification

Status: constructed, not machine-checked.

## Scope

This specification covers the Python-side CSR reconstruction at the end of
`BaseLibSVM._sparse_fit`:

```python
dual_coef_indices = np.tile(np.arange(n_SV), n_class)
dual_coef_indptr = np.arange(n_class + 1) * n_SV
self.dual_coef_ = sp.csr_matrix(
    (dual_coef_data, dual_coef_indices, dual_coef_indptr),
    (n_class, n_SV))
```

It does not prove libsvm optimization, Cython memory-copy routines, prediction,
or total correctness of training. It proves the fitted `dual_coef_` CSR
structure is well formed for the boundary case reported in the issue and for
the non-empty cases affected by the same expression.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "ZeroDivisionError in _sparse_fit for SVM with empty support_vectors_" | Sparse fitting must allow `n_SV == 0`. | Encoded by domain `n_SV >= 0`. |
| E-002 | `benchmark/PROBLEM.md` | "No error is thrown and `self.dual_coef_ = sp.csr_matrix([])`" | Empty SVR support vectors produce an empty sparse `dual_coef_`. | Encoded by all-zero `indptr` and shape `(1, 0)` for SVR. |
| E-003 | `repo/sklearn/svm/classes.py` | SVR documents `dual_coef_` shape `[1, n_SV]`. | Preserve one-row coefficient layout for regression. | Encoded by `n_class = 1` for regressors. |
| E-004 | `repo/sklearn/svm/classes.py` | SVC/NuSVC document `dual_coef_` shape `[n_class-1, n_SV]`. | Preserve classifier coefficient row count. | Encoded by `n_class = len(classes_) - 1`. |
| E-005 | `repo/sklearn/svm/tests/test_sparse.py` | Sparse tests assert sparse `dual_coef_` and dense/sparse coefficient parity. | Preserve sparse representation and coefficient ordering. | Encoded as frame and non-regression obligations. |
| E-006 | `repo/sklearn/svm/libsvm_sparse.pyx` | Cython allocates `sv_coef_data` from `(n_class-1) * SV_len`. | Data length matches row count times support-vector count. | Used as a proof side condition. |

## Domain And Preconditions

After `libsvm_sparse.libsvm_sparse_train` returns:

- `n_class >= 1`;
- `n_SV == self.support_vectors_.shape[0]`;
- `n_SV >= 0`;
- `dual_coef_data.size == n_class * n_SV`;
- `dual_coef_indices == np.tile(np.arange(n_SV), n_class)`.

The `n_class >= 1` condition is public-code supported: regression and one-class
models use `n_class = 1`; classifiers compute `len(self.classes_) - 1`, and
`BaseSVC._validate_targets` rejects fewer than two classes.

## Postconditions

The reconstructed sparse coefficient matrix satisfies:

- `dual_coef_indptr == [r * n_SV for r in range(n_class + 1)]`;
- `len(dual_coef_indptr) == n_class + 1`;
- `dual_coef_indptr[0] == 0`;
- `dual_coef_indptr[-1] == n_class * n_SV`;
- `dual_coef_indptr` is nondecreasing;
- `self.dual_coef_.shape == (n_class, n_SV)`;
- if `n_SV == 0`, `dual_coef_indptr` is `[0] * (n_class + 1)` and the CSR
  matrix stores no elements;
- if `n_SV > 0`, `dual_coef_indptr` is identical to the row boundaries intended
  by the pre-fix expression.

## Formal Core

The K formalization files are:

- `fvk/mini-python-numpy.k`
- `fvk/svm-sparse-fit-spec.k`

The main claim states that executing:

```python
dual_coef_indptr = np.arange(n_class + 1) * n_SV
```

from any state satisfying `n_class >= 1` and `n_SV >= 0` reaches a state where
`dual_coef_indptr` is `scale(range(0, n_class + 1), n_SV)`, i.e. the sequence of
row starts `[0, n_SV, 2*n_SV, ..., n_class*n_SV]`.

## Frame Conditions

The proof and source diff leave unchanged:

- the libsvm sparse training call;
- support-vector data and indices;
- `_n_support`, `intercept_`, `probA_`, `probB_`, and `fit_status_`;
- public estimator method signatures;
- the explicit CSR shape `(n_class, n_SV)`.

## Adequacy

The formal spec is adequate for the reported bug because it keeps the property
axis that failed in the issue: the CSR `indptr` sequence and its behavior when
`n_SV == 0`. A model that abstracted away `indptr` would not distinguish the
pre-fix crash from the fixed empty CSR case, so this spec models `indptr`
directly.
