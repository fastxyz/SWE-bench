# Constructed Proof

Status: constructed, not machine-checked.

## Claim

For every original matrix `A`, inserted matrix `B`, normalized position `P`,
valid row `i`, and valid result column `j`, `_eval_col_insert(P, B)` implements
the intended column insertion entry mapping:

```text
if j < P:
    result[i, j] = A[i, j]
elif P <= j < P + B.cols:
    result[i, j] = B[i, j - P]
else:
    result[i, j] = A[i, j - B.cols]
```

The public `col_insert` method supplies the helper preconditions by normalizing
`P` and checking equal row counts before calling `_eval_col_insert`.

## Symbolic proof

Let `R = A.rows`, `C = A.cols`, `K = B.cols`, and assume:

```text
B.rows = R
0 <= P <= C
0 <= K
0 <= i < R
0 <= j < C + K
```

### Shape

The helper returns:

```python
self._new(self.rows, self.cols + other.cols, lambda i, j: entry(i, j))
```

By the trusted `_new` matrix-construction contract, the result has `R` rows and
`C + K` columns. This discharges PO-3 and the K shape claims.

### Entry case 1: `j < P`

The first branch fires:

```python
return self[i, j]
```

Since `0 <= j < P <= C`, the source column is valid and the entry equals the
left-frame specification. This discharges PO-4.

### Entry case 2: `P <= j < P + K`

The second branch fires:

```python
return other[i, j - pos]
```

Here `pos` is the normalized `P`, so `0 <= j - P < K`. The source column in
`other` is valid and the entry equals the inserted-block specification. This
discharges PO-5.

### Entry case 3: `P + K <= j < C + K`

The final branch fires:

```python
return self[i, j - other.cols]
```

Since `P + K <= j < C + K`, subtracting `K` gives `P <= j - K < C`. The source
column in `self` is valid and is exactly the original column that should appear
after the inserted block. This discharges PO-6.

The pre-V1 expression `j - P - K` would map `j = P + K` to original column `0`
instead of `P`, which contradicts PO-6 and reproduces the reported shifted
identity block.

## No loop circularity

The changed code has no loop or recursive call. The proof is a finite branch
case split plus integer-bound reasoning, so no circularity claim is required.

## Adequacy gate

The English paraphrase of every formal claim is in
`fvk/FORMAL_SPEC_ENGLISH.md`, and the claim-by-claim audit is in
`fvk/SPEC_AUDIT.md`. All claims pass against the intent-only spec in
`fvk/INTENT_SPEC.md`. The proof therefore supports the code decision instead of
proving a legacy-derived contract.

## Machine-check commands

These commands are recorded for a future K environment. They were not executed
in this benchmark session.

```sh
cd fvk
kompile mini-matrix.k --backend haskell
kast --backend haskell col-insert-spec.k
kprove col-insert-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Test-redundancy recommendation

No tests were modified. If the K proof is machine-checked later, a direct unit
test that asserts only the in-domain piecewise entry mapping for
`_eval_col_insert` would be subsumed by the proof. Integration tests, public API
guard tests, sparse-matrix behavior tests, and regression tests documenting the
GitHub issue should be kept.

## Residual risk

This is a partial-correctness proof over a mini-matrix semantics. It assumes the
existing matrix constructor `_new` faithfully exposes the supplied entry
function. The proof was constructed but not machine-checked, per task
constraints.
