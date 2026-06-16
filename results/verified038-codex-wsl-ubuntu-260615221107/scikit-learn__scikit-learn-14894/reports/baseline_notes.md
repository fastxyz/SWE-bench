# Baseline Notes

## Root cause

`BaseLibSVM._sparse_fit` reconstructs `self.dual_coef_` as a CSR matrix after
calling `libsvm_sparse.libsvm_sparse_train`. The CSR `indptr` was computed with:

```python
np.arange(0, dual_coef_indices.size + 1, dual_coef_indices.size / n_class)
```

`dual_coef_indices.size / n_class` is the number of support vectors. For sparse
SVR fits where libsvm returns no support vectors, that value is zero, so
`np.arange` is called with a zero step and raises `ZeroDivisionError`.

## Changed files

`repo/sklearn/svm/base.py`

The sparse fit path now computes `dual_coef_indptr` as:

```python
np.arange(n_class + 1) * n_SV
```

For non-empty support vectors this produces the same CSR row pointer sequence as
before: `0, n_SV, 2 * n_SV, ...`. For the empty support-vector case it produces
an all-zero `indptr` of length `n_class + 1`, allowing SciPy to construct an
empty CSR `dual_coef_` with shape `(n_class, 0)`.

## Assumptions and alternatives considered

I assumed the sparse path should preserve the existing `dual_coef_` shape
contract, i.e. `(n_class, n_SV)`, because the dense fit succeeds for the same
SVR input and the sparse path already passes that explicit shape to
`sp.csr_matrix`.

I considered special-casing `n_SV == 0`, but rejected it because the row-pointer
formula based on multiples of `n_SV` handles both empty and non-empty models
without changing the surrounding logic.

I also considered changing `libsvm_sparse.pyx` to return a prebuilt CSR
`dual_coef_`, but rejected that as a larger change than necessary. The bug is in
the Python-side CSR pointer reconstruction, and the Cython output already
contains enough data to represent the empty case correctly.

No tests or code were run, per the benchmark instruction that this session has
no execution environment and must not execute tests or code.
