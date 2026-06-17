# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Domain precondition

If `A.domain.is_ZZ` is false, `_hermite_normal_form` raises `DMDomainError`.
If `A.domain.is_ZZ` is true, all arithmetic is exact integer arithmetic.

## PO2: Outer-loop bounds

The outer loop starts with `i = m - 1` and moves upward. It stops when either
all rows have been considered or `k == 0`. The update pattern preserves
`0 <= k <= n`, including the zero-row case where `k` is restored after the
temporary decrement.

## PO3: Pairwise column operation is unimodular

For row entries `a = A[i][k]`, `b = A[i][j]`, and `d = gcd(a, b)`,
`_gcdex(a, b)` returns `u, v, d` with `u*a + v*b = d`. With
`r = a/d` and `s = b/d`, the column update matrix

```text
[[ u,  v],
 [-s,  r]]
```

has determinant `u*r + v*s = 1`. Therefore each `add_columns` call in the
left-reduction loop preserves the integer column module.

## PO4: Pivot discovery is complete over processed rows

After the left-reduction loop for row `i`, entries in columns left of `k` are
zero in row `i`, and `A[i][k]` is the gcd of the active prefix of that row. If
that gcd is zero, no pivot is available in that row and `k` is restored. If it
is nonzero, the algorithm has found one additional pivot column.

## PO5: Dropped prefix columns are zero after the full scan

When the outer loop finishes after considering all rows with `k > 0`, every
column left of `k` is zero in every row. Dropping those prefix columns therefore
does not change the generated integer column module.

## PO6: Returned column count equals rank

Every nonzero pivot found by PO4 increases the rank of the retained suffix by
one, and PO5 shows no nonzero rank remains in the dropped prefix. Therefore the
returned suffix has exactly `rank(A)` columns.

## PO7: Issue instance derivation

For `B = [[1, 12], [0, 8], [0, 5]]`, the bottom row first makes column `1` a
pivot. The next row has no available prefix pivot, so `k` is restored. The top
row then makes column `0` a pivot and reduces column `1` by `12` times column
`0`, yielding `[[1, 0], [0, 8], [0, 5]]`.

## PO8: Rank-deficient tall derivation

For a rank-positive tall matrix whose nonzero data appears above the bottom
`n` rows, the full scan must still find all available pivots. For example,
`[[2, 7], [0, 0], [0, 0]]` has rank `1`, so the result must have one column,
not zero columns.

## PO9: Public compatibility frame

No public signature, return type, domain guard, modular-`D` dispatch, or wrapper
conversion behavior changes.
