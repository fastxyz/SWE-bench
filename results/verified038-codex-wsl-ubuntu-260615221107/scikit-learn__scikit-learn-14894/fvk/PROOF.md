# Constructed Proof

Status: constructed, not machine-checked.

## Claim

For every sparse libsvm reconstruction state satisfying:

```text
n_class >= 1
n_SV >= 0
dual_coef_data.size == n_class * n_SV
support_vectors_.shape[0] == n_SV
```

the V1 sparse fit code constructs a valid CSR `dual_coef_` with shape
`(n_class, n_SV)`. In particular, when `n_SV == 0`, the row pointer is all zeros
and no `ZeroDivisionError` occurs.

## Symbolic execution

The modeled V1 statement is:

```python
dual_coef_indptr = np.arange(n_class + 1) * n_SV
```

Under the mini semantics in `mini-python-numpy.k`:

1. Lookup `n_class`, yielding symbolic `NC`.
2. Add one, yielding `NC + 1`.
3. Evaluate `arange(NC + 1)`, yielding `range(0, NC + 1)`.
4. Lookup `n_SV`, yielding symbolic `NSV`.
5. Multiply the integer list by `NSV`, yielding
   `scale(range(0, NC + 1), NSV)`.
6. Assign that value to `dual_coef_indptr`.

The reachability claim in `svm-sparse-fit-spec.k` states exactly this transition
for all `NC >= 1` and `NSV >= 0`.

## Arithmetic proof

For each row `r` with `0 <= r <= NC`, `scale(range(0, NC + 1), NSV)` has value:

```text
r * NSV
```

Therefore:

- the first entry is `0 * NSV == 0`;
- the last entry is `NC * NSV`;
- the sequence has `NC + 1` entries;
- if `NSV == 0`, every entry is zero;
- if `NSV > 0`, the sequence is strictly increasing by `NSV`;
- if `NSV >= 0`, the sequence is nondecreasing.

## CSR proof

`dual_coef_indices = np.tile(np.arange(n_SV), n_class)` has
`n_class * n_SV` entries. Each entry is an integer column index from `0` to
`n_SV - 1`; if `n_SV == 0`, the sequence is empty.

With PO-DATA-LENGTH, `dual_coef_data.size == dual_coef_indices.size`. With
C-INDPTR, `dual_coef_indptr[-1] == n_class * n_SV`, so the final row pointer
equals the data and index lengths. The explicit CSR shape remains
`(n_class, n_SV)`.

Thus the CSR constructor receives a well-formed empty matrix in the reported
case and a well-formed matrix with the same row boundaries as before in
non-empty cases.

## Non-regression proof

For `n_SV > 0`, the pre-fix step was:

```text
dual_coef_indices.size / n_class
```

Since `dual_coef_indices.size == n_class * n_SV`, the mathematical value of that
step is `n_SV`. The pre-fix intended row boundaries were therefore:

```text
[0, n_SV, 2*n_SV, ..., n_class*n_SV]
```

V1 computes the same sequence directly as:

```text
np.arange(n_class + 1) * n_SV
```

For `n_SV == 0`, the pre-fix expression becomes an invalid zero-step `arange`;
V1 still computes the all-zero sequence required by CSR.

## Adequacy

The proof target is adequate because the issue is specifically a failure in CSR
row-pointer construction. The model explicitly represents the row-pointer
sequence, the empty-support-vector boundary, and the final CSR shape. It does
not claim to prove libsvm's optimizer or SciPy internals beyond the standard CSR
shape preconditions listed in `PROOF_OBLIGATIONS.md`.

## Machine-check commands

These commands are emitted for later checking only. They were not run in this
session.

```sh
cd fvk
kompile mini-python-numpy.k --backend haskell
kast --backend haskell svm-sparse-fit-spec.k
kprove svm-sparse-fit-spec.k
```

Expected machine-check result in a K environment for this fragment: `#Top` for
the stated reachability claim.

## Test recommendation

No test deletion is recommended from this constructed proof. A focused
regression test for sparse `SVR` with zero support vectors would be appropriate,
but the benchmark forbids modifying test files.
