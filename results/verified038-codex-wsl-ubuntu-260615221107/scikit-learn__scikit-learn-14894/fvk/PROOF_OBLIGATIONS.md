# Proof Obligations

Status: constructed, not machine-checked.

## PO-INDPTR-TOTAL

For all integers `n_class >= 1` and `n_SV >= 0`, the expression:

```python
np.arange(n_class + 1) * n_SV
```

is defined and does not perform division or use an `np.arange` step derived from
`n_SV`.

Status: discharged by construction. `np.arange(n_class + 1)` uses the default
step of one, so `n_SV == 0` only scales the resulting sequence.

## PO-EMPTY-CSR

For all `n_class >= 1`, if `n_SV == 0`, then:

```text
dual_coef_indices == []
dual_coef_indptr == [0] * (n_class + 1)
shape == (n_class, 0)
```

and CSR construction has a row pointer of the required length.

Status: discharged. `np.tile(np.arange(0), n_class)` is empty, and
`np.arange(n_class + 1) * 0` is the all-zero sequence of length `n_class + 1`.

## PO-DATA-LENGTH

For every sparse libsvm return in this reconstruction domain:

```text
dual_coef_data.size == n_class * n_SV
dual_coef_indices.size == n_class * n_SV
```

Status: discharged under the libsvm wrapper contract and public fitted-shape
contracts. Cython allocates coefficient data from the libsvm row count times
`SV_len`, while Python uses one row for regressors/one-class and
`len(classes_) - 1` rows for classifiers.

## PO-CSR-SHAPE

Given PO-DATA-LENGTH and C-INDPTR, `sp.csr_matrix` receives:

- `len(indptr) == n_class + 1`;
- `indptr[0] == 0`;
- `indptr[-1] == len(data) == len(indices)`;
- every index in `dual_coef_indices` is in `[0, n_SV)`, or the index array is
  empty when `n_SV == 0`;
- explicit shape `(n_class, n_SV)`.

Status: discharged by arithmetic over the generated arrays.

## PO-NONREGRESSION

For all `n_class >= 1` and `n_SV > 0`, V1 row pointers equal the pre-fix row
boundaries:

```text
np.arange(n_class + 1) * n_SV
==
np.arange(0, n_class * n_SV + 1, n_SV)
```

Status: discharged by sequence extensionality. The value at row `r` is
`r * n_SV` for both expressions, for every `0 <= r <= n_class`.

## PO-FRAME

The source change preserves every value not derived from
`dual_coef_indptr`.

Status: discharged by diff inspection. The only source change is the expression
that computes `dual_coef_indptr`; the libsvm call, support-vector fields,
coefficient data, explicit CSR shape, and public method signatures are unchanged.

## PO-ADEQUACY

The formal model must distinguish the pre-fix failure from the V1 behavior.

Status: discharged for the audited property. The model includes the `indptr`
sequence explicitly. The pre-fix path has an undefined zero-step operation when
`n_SV == 0`; V1 has a total sequence expression over `n_SV >= 0`.
