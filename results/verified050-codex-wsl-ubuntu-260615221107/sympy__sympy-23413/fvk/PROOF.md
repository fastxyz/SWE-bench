# Constructed Proof

Status: constructed, not machine-checked. No K tooling, Python, or tests were
run.

## K artifacts

- `mini-hnf.k`: a minimal HNF/matrix abstraction that preserves the observable
  properties relevant to the defect.
- `hnf-spec.k`: reachability claims for the HNF contract, the issue instance,
  and the rank-deficient tall-matrix regression found in V1.

Commands to machine-check later:

```sh
cd fvk
kompile mini-hnf.k --backend haskell
kast --backend haskell hnf-spec.k
kprove hnf-spec.k
```

Expected result after a real machine check: `#Top`.

## Proof sketch

The proof is by symbolic execution of the outer row loop, with the inner column
loops summarized by PO3 and PO4.

Invariant I1: after each successful column operation, the working matrix equals
the input matrix multiplied by a unimodular integer matrix. Therefore it
generates the same integer column module as the input.

Invariant I2: before processing a row, `k` is the leftmost retained pivot
column. Columns to the right of `k` contain the pivots already found in lower
processed rows.

Invariant I3: after processing row `i`, either the active prefix of that row was
zero and `k` is restored, or one pivot is found and `k` remains one position
farther left. In the pivot case, entries to the right in row `i` are reduced
modulo the pivot.

The V2 loop scans rows `m - 1` down to `0`, stopping early only when `k == 0`.
Thus every row that can contribute a pivot is considered. If the scan ends with
`k > 0`, PO5 says all dropped prefix columns are zero. If it ends with `k == 0`,
all original columns have become retained pivots. In both cases the returned
suffix preserves the input column module and has exactly `rank(A)` columns.

## Issue instance

For

```text
B = [[1, 12],
     [0,  8],
     [0,  5]]
```

symbolic execution gives:

1. Row `2` makes column `1` a pivot with value `5`.
2. Row `1` has no nonzero active prefix for column `0`, so `k` is restored.
3. Row `0` makes column `0` a pivot with value `1`.
4. The right-reduction step subtracts `12` times column `0` from column `1`.

The result is

```text
[[1, 0],
 [0, 8],
 [0, 5]]
```

which makes the user's row-style transform produce
`[[5, 8, 0], [0, 0, 1]]`.

## V1 finding discharge

V1 restored the old result whenever the extended scan did not recover every
input column as a pivot. That breaks PO6 for rank-deficient tall matrices. V2
removes the fallback, so rank-positive tall matrices retain their rank-many
HNF columns.

## Residual risk

This is a constructed proof over a mini-HNF abstraction, not a machine-checked
proof over full Python. The trusted base is the adequacy of the abstraction,
the unimodular column-operation lemmas, and the K reachability tooling once the
recorded commands are actually run.

Termination is argued structurally from the finite row and column loops but is
not machine-proved.

## Test guidance

No tests were removed or edited. After machine-checking, issue-instance and
direct HNF tests for the covered in-domain cases would be subsumed by the proof,
but test removal remains recommendation-only and conditioned on `kprove`
returning `#Top`.
