# Proof

Status: constructed, not machine-checked.

## Claims

The proof target is `BlockMatrix._blockmul` as modeled in
`mini-blockmatrix.k` and specified in `blockmul-spec.k`.

Function-level claims:

- `NORMALIZE-SCALAR-ZERO`
- `NORMALIZE-MATRIX-PRESERVE`
- `BLOCKMUL-COMPATIBLE-ZERO-ENTRY`
- `BLOCKMUL-COMPATIBLE-MATRIX-ENTRY`
- `BLOCKMUL-RESULT-ROW-SHAPE`
- `BLOCKMUL-RESULT-COL-SHAPE`
- `BLOCKMUL-REPEATED-SAFE`
- `BLOCKMUL-NONBLOCK-FALLBACK`
- `BLOCKMUL-INCOMPATIBLE-FALLBACK`

No loop or recursive circularity claims are needed because `_blockmul` has no
loop or recursion in the audited path.

## Constructed Proof Sketch

1. `blockMul(A, block(B))` symbolically executes to `product(A, B)` when
   `compatible(A, B)` is true. This models the compatible `BlockMatrix` branch.

2. For any result position `(I, J)`, `entry(product(A, B), I, J)` and
   `resultEntry(A, B, I, J)` rewrite to
   `normalize(rawEntry(A, B, I, J), rowSize(A, I), colSize(B, J))`.

3. If `rawEntry(A, B, I, J)` is `scalarZero`, `normalize` rewrites to
   `zeroMatrix(rowSize(A, I), colSize(B, J))`. This discharges the reported
   defect: scalar zero is not stored as the result block.

4. If `rawEntry(A, B, I, J)` is already a matrix block `MB`, `normalize`
   rewrites to `MB`. This discharges the non-regression frame condition for
   ordinary matrix-valued product entries.

5. `entryRows(product(A, B), I, J)` rewrites to `rowSize(A, I)` and
   `entryCols(product(A, B), I, J)` rewrites to `colSize(B, J)`. This proves the
   result block dimensions needed by later block-size access.

6. `isMatrixEntry(product(A, B), I, J)` rewrites to `true` under compatibility,
   proving the repeated-multiplication safety obligation in the mini-semantics.

7. If `compatible(A, B)` is false, `blockMul(A, block(B))` rewrites to
   `fallback(A, block(B))`. If the right operand is not a `BlockMatrix`,
   `blockMul(A, nonBlock(X))` rewrites to `fallback(A, nonBlock(X))`. These
   discharge the fallback frame conditions.

## Regression Argument

The only behavior V1 changes is an exact scalar-zero raw product entry in the
compatible branch. The proof re-derives these existing scenarios:

- matrix-valued product entries remain unchanged;
- non-`BlockMatrix` operands still use fallback multiplication;
- incompatible `BlockMatrix` operands still use fallback multiplication;
- result row and column block sizes are unchanged from the mathematically
  expected block product.

Therefore no FVK finding forces a V2 code edit.

## Exact Commands To Machine-Check Later

These commands are recorded but were not executed in this session.

```sh
cd fvk
kompile mini-blockmatrix.k --backend haskell \
  --main-module MINI-BLOCKMATRIX \
  --syntax-module MINI-BLOCKMATRIX-SYNTAX

# Optional parse sanity check; flags may need adjustment for the installed K version.
kast blockmul-spec.k \
  --definition mini-blockmatrix-kompiled \
  --module BLOCKMUL-SPEC \
  --sort Claim

kprove blockmul-spec.k \
  --definition mini-blockmatrix-kompiled \
  --spec-module BLOCKMUL-SPEC
```

Expected `kprove` result after any syntax/tool-version adjustments: `#Top`.

## Honesty Gate

No K command, Python command, or test was run. This proof is constructed, not
machine-checked. Test-removal recommendations are therefore not valid.

## Test Recommendation

Keep existing tests. A focused regression test for repeated multiplication with
zero blocks would be useful, but this task forbids modifying test files.
