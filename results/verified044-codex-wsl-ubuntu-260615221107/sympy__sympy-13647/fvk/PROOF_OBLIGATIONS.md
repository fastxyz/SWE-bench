# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Public position normalization

For non-empty `self`, `col_insert` maps any integer `pos` to a normalized
position `P` satisfying `0 <= P <= self.cols`.

Status: discharged by source inspection of the public guard:

- negative positions are first translated by `self.cols + pos`;
- still-negative positions clamp to `0`;
- positions above `self.cols` clamp to `self.cols`.

## PO-2: Public row precondition

For non-empty `self`, `_eval_col_insert` is called only when
`self.rows == other.rows`; otherwise `ShapeError` is raised.

Status: discharged by source inspection. V1 does not alter this guard.

## PO-3: Result shape

Under `self.rows == other.rows`, `0 <= P <= self.cols`, and
`other.cols >= 0`, `_eval_col_insert(P, other)` returns a matrix with:

- `self.rows` rows;
- `self.cols + other.cols` columns.

Status: discharged by the `_new(self.rows, self.cols + other.cols, entry)`
call and K claims `C-SHAPE-ROWS` and `C-SHAPE-COLS`.

## PO-4: Left frame

For every valid row `i` and result column `j` where `j < P`,
`result[i, j] == self[i, j]`.

Status: discharged by the first branch of `entry(i, j)`.

## PO-5: Inserted block

For every valid row `i` and result column `j` where
`P <= j < P + other.cols`, `result[i, j] == other[i, j - P]`.

Status: discharged by the second branch of `entry(i, j)`. The source index
`j - P` is valid because `0 <= j - P < other.cols`.

## PO-6: Right frame

For every valid row `i` and result column `j` where
`P + other.cols <= j < self.cols + other.cols`,
`result[i, j] == self[i, j - other.cols]`.

Status: discharged by the V1 branch:

```python
return self[i, j - other.cols]
```

The source index is valid because `P <= j - other.cols < self.cols`. This is
also the obligation the pre-V1 expression `j - pos - other.cols` failed for any
interior insertion with `pos > 0`.

## PO-7: Zero-width inserted matrix

If `other.cols == 0`, the inserted-block interval is empty and the left/right
frame obligations reduce to `result[i, j] == self[i, j]` for all columns.

Status: discharged by PO-4 and PO-6. This is not the issue's primary example,
but the V1 expression handles it correctly.

## PO-8: Compatibility

V1 must not change the public signature, dispatch shape, result dimensions, or
row mismatch error behavior.

Status: discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. No additional source
change is required.

## PO-9: Machine-check commands

The proof artifacts should be machine-checkable later with:

```sh
cd fvk
kompile mini-matrix.k --backend haskell
kast --backend haskell col-insert-spec.k
kprove col-insert-spec.k
```

Status: commands recorded only. They were not executed, per task constraints.

## PO-10: Null-matrix public branch

If `self` is a null matrix, public `col_insert` returns `type(self)(other)`
before position normalization and before `_eval_col_insert`.

Status: discharged by source inspection. V1 does not alter this branch, and no
FVK finding indicates it contributes to the reported non-null matrix defect.
