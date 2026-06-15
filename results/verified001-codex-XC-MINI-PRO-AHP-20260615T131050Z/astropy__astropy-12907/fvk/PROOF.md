# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Machine-check commands to run later

```sh
kompile fvk/mini-python-separability.k --backend haskell
kast --backend haskell fvk/separability-spec.k
kprove fvk/separability-spec.k
```

Expected machine-check result after a working K setup: `#Top` for all claims.

## Proof target

The proof target is `_cstack` on coordinate matrices produced by recursive
`_separable` evaluation of `CompoundModel('&')`. The intended contract is the
block matrix contract in `fvk/SPEC.md`.

## Symbolic proof sketch

Let `L` have `lr` rows and `lc` columns. Let `R` have `rr` rows and `rc`
columns. `_cstack` computes `noutp = lr + rr`.

For an ndarray left operand, V1 keeps the existing code:

```python
cleft = np.zeros((noutp, left.shape[1]))
cleft[: left.shape[0], : left.shape[1]] = left
```

Therefore `cleft[i, j] = L[i, j]` for `0 <= i < lr` and `0 <= j < lc`, while
`cleft[i, j] = 0` for rows `lr <= i < lr + rr`.

For an ndarray right operand, V1 has:

```python
cright = np.zeros((noutp, right.shape[1]))
cright[-right.shape[0]:, -right.shape[1]:] = right
```

Because `cright` has exactly `rc` columns, the column slice
`-right.shape[1]:` spans all columns of `cright`. The row slice
`-right.shape[0]:` spans rows `lr` through `lr + rr - 1`. Therefore
`cright[lr + i, j] = R[i, j]` for `0 <= i < rr` and `0 <= j < rc`, while
`cright[i, j] = 0` for rows `0 <= i < lr`.

Finally, `np.hstack([cleft, cright])` concatenates the `lc` left columns and
the `rc` right columns. Thus the result `C` has shape `(lr + rr, lc + rc)` and:

```text
C[i, j]             = L[i, j]       for left-block entries
C[lr + i, lc + j]   = R[i, j]       for right-block entries
C[i, lc + j]        = 0             for upper-right off-block entries
C[lr + i, j]        = 0             for lower-left off-block entries
```

These are PO-1 through PO-4.

For PO-5, instantiate `R = _cstack(B, C)`. PO-3 says every entry of this nested
right matrix is copied unchanged into the lower-right block of `_cstack(A, R)`.
Therefore zeros inside the nested `B & C` block, including the off-diagonal zeros
of `Linear1D & Linear1D`, remain zeros when the nested compound model is placed
to the right of `Pix2Sky_TAN`.

## Reported example derivation

Let:

```text
P = [[1, 1],
     [1, 1]]
D = [[1, 0],
     [0, 1]]
```

By PO-3, `_cstack(P, D)` places `D` unchanged in the lower-right block. By PO-4,
the cross blocks are zero. The resulting matrix is:

```text
[[1, 1, 0, 0],
 [1, 1, 0, 0],
 [0, 0, 1, 0],
 [0, 0, 0, 1]]
```

`separability_matrix` then converts nonzero entries to `True` and zero entries
to `False`, yielding the intended boolean result from the issue.

## Residual risk

The proof is partial correctness only and is constructed, not machine-checked.
It does not prove unrelated separability operators (`|`, arithmetic operators)
or private helper behavior outside the matrix branch reached by public
`separability_matrix` for nested `&` compound models.

## Test recommendation

Do not remove tests. Because the proof has not been machine-checked and covers a
focused helper contract, existing tests should be kept. A regression test for
`separability_matrix(m.Pix2Sky_TAN() & (m.Linear1D(10) & m.Linear1D(5)))` would
be directly subsumed only after `kprove` returns `#Top`, but this task forbids
modifying tests.
