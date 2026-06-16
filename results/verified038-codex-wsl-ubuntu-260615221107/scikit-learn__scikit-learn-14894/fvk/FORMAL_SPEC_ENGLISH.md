# Formal Spec In English

Status: constructed, not machine-checked.

## Claim C-INDPTR

For every sparse fit reconstruction state with `n_class >= 1` and `n_SV >= 0`,
executing the V1 expression:

```python
dual_coef_indptr = np.arange(n_class + 1) * n_SV
```

produces the integer sequence:

```text
[0 * n_SV, 1 * n_SV, ..., n_class * n_SV]
```

This sequence has length `n_class + 1`, starts at zero, ends at
`n_class * n_SV`, and is nondecreasing. If `n_SV == 0`, every entry is zero.

## Claim C-CSR

For every reconstruction state satisfying:

```text
dual_coef_data.size == n_class * n_SV
dual_coef_indices == tile(arange(n_SV), n_class)
```

the `indptr` from C-INDPTR is a valid CSR row pointer for a matrix with shape
`(n_class, n_SV)`. In the empty case, the CSR matrix has zero stored elements and
shape `(n_class, 0)`.

## Claim C-NONREGRESSION

For `n_SV > 0`, V1's `indptr` is extensionally equal to the pre-fix expression's
intended row boundaries:

```text
np.arange(0, n_class * n_SV + 1, n_SV)
```

For `n_SV == 0`, the pre-fix expression is undefined because its step is zero,
while V1 remains defined.

## Claim C-FRAME

The V1 change affects only `dual_coef_indptr`. It preserves the libsvm call, the
support vectors, support indices, intercepts, probability arrays, fit status,
public estimator signatures, and the explicit CSR shape `(n_class, n_SV)`.
