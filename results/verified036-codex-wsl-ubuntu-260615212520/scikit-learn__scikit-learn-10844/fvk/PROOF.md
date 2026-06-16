# FVK PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claim

For valid contingency-derived counts `tk`, `pk`, and `qk`, V1 returns the same
mathematical Fowlkes-Mallows score required by the public docs and issue while
avoiding the integer product `pk * qk`.

## Proof Sketch

1. From PO-1, `tk`, `pk`, and `qk` are nonnegative pair counts and
   `tk <= pk`, `tk <= qk`.
2. If `tk == 0`, the implementation returns `0.`. This is the documented
   zero-score boundary and avoids denominator evaluation. This proves PO-2.
3. If `tk > 0`, then PO-1 gives `pk > 0` and `qk > 0`, proving PO-3.
4. On the nonzero branch, V1 evaluates `sqrt(tk / pk) * sqrt(tk / qk)`.
   Because both divisions are defined and `tk >= 0`, PO-4 shows this equals
   `tk / sqrt(pk * qk)`, the public FMI formula.
5. The expression in step 4 contains no integer multiplication of `pk` and
   `qk`. The two ratios are in `(0, 1]`, so the remaining multiplication is a
   bounded floating multiplication rather than the reported overflowing integer
   product. This proves PO-5.
6. Since count construction and the public function signature are unchanged,
   PO-6 and PO-8 preserve public examples, invariance properties, and callers.

Therefore V1 satisfies the stated score-kernel contract. No V2 source change is
required.

## Machine-Oriented Proof Shape

The compact K model has no loop circularity because the audited source line is
straight-line arithmetic after counts are computed.

- `mini-python.k` defines `fmi(TK, PK, QK)` with two rewrite rules:
  - `TK == 0` rewrites to `zeroScore`.
  - `TK =/= 0` rewrites to `mulScore(sqrtScore(ratio(TK, PK)),
    sqrtScore(ratio(TK, QK)))`.
- `fowlkes-mallows-spec.k` defines:
  - `validCounts(TK, PK, QK)`.
  - `expectedFmi(TK, PK, QK)`.
  - A simplification lemma equating the V1 expression with `expectedFmi` under
    valid positive counts.
  - Claims for the zero branch and the nonzero branch.

The proof is by symbolic execution of the selected rule, then a consequence
step using the algebraic simplification lemma.

## Adequacy Check

The formal English contract says exactly:

- Return zero for `tk == 0`.
- Return the FMI formula for `tk > 0`.
- Do not form the overflowing integer denominator product.

These obligations are traced to I1 through I6 in `SPEC.md`. No formal claim
preserves legacy behavior merely because V1 happens to produce it.

## Residual Risk

- The proof is constructed, not machine-checked.
- The compact semantics models the arithmetic kernel rather than the full
  Python/NumPy/SciPy execution stack.
- Floating-point rounding is abstracted as mathematical real arithmetic. This
  is sufficient for the reported overflow-localization question but not for a
  bit-level IEEE-754 proof.
- Termination is not separately proved. The audited arithmetic tail is
  straight-line; broader source termination depends on unchanged NumPy/SciPy
  operations.

## Test Recommendation

Do not remove any tests in this benchmark. If the K artifacts were later
machine-checked, point tests that assert only the arithmetic formula for fixed
valid counts would be subsumed. Existing public tests over label arrays also
exercise input checking, contingency construction, scorer wiring, and
integration behavior outside this compact proof, so they should be kept.

## Reproduce Later

Commands to run in an environment with K installed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/fowlkes-mallows-spec.k
kprove fvk/fowlkes-mallows-spec.k
```
