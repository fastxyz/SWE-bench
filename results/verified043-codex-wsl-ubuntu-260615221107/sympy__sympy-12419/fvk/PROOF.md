# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or test commands were executed.

## Claims Proved

P1. `Identity._entry(i, j)` implements the mathematical identity-matrix entry relation: `1` on definite diagonal entries, `0` on definite off-diagonal entries, and `KroneckerDelta(i, j)` when symbolic equality is undecidable.

P2. The exact interval `Piecewise` emitted by `deltasummation` can be summed over that same interval by summing only its first branch.

P3. For positive integer `n`, the nested sum of all entries of `Identity(n)` over `0..n-1` is `n`.

## Symbolic Execution Sketch

1. Entry construction:

   ```text
   Identity._entry(i, j)
   => KroneckerDelta(i, j)
   ```

   If `i - j` is zero, `KroneckerDelta.eval` returns `1`. If `i - j` is definitely nonzero, it returns `0`. Otherwise it remains `KroneckerDelta(i, j)`.

2. Inner sum for an identity matrix:

   ```text
   Sum(KroneckerDelta(i, j), (i, 0, n - 1)).doit()
   => Piecewise((1, Interval(0, n - 1).as_relational(j)), (0, True))
   ```

   This follows from the existing `deltasummation` rule that solves the delta for the summation index and emits a zero-fallback Piecewise over the original interval.

3. Outer sum over the same interval:

   ```text
   Sum(Piecewise((1, Interval(0, n - 1).as_relational(j)), (0, True)),
       (j, 0, n - 1)).doit()
   => Sum(1, (j, 0, n - 1)).doit()
   => n
   ```

   The V2 `eval_sum` branch justifies the first rewrite only when the Piecewise condition is exactly the active interval relation, the fallback branch is `0`, and the interval width is known nonnegative.

4. Fixed row and fixed column sums:

   ```text
   Sum(KroneckerDelta(0, i), (i, 0, n - 1)).doit()
   => Piecewise((1, Interval(0, n - 1).as_relational(0)), (0, True))
   => 1
   ```

   Since `n` is positive, `0` is inside `0..n-1`. The same argument applies to `Sum(KroneckerDelta(i, 0), (i, 0, n - 1))`.

## VCs

VC1. Definite equality and inequality cases of `KroneckerDelta` are preserved. Source inspection discharges this through `KroneckerDelta.eval`.

VC2. `n` positive integer implies `(n - 1) - 0` is nonnegative. This discharges the V2 guard `dif.is_nonnegative` for the reported interval.

VC3. `eval_sum(1, (j, 0, n - 1)) = 1 * ((n - 1) - 0 + 1) = n`. This follows from the existing branch `if i not in f.free_symbols: return f*(b - a + 1)`.

VC4. Compatibility frame: no changed method signatures and no touched tests. Source diff discharges this.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-sympy-identity.k --backend haskell
kast --backend haskell fvk/identity-sum-spec.k
kprove fvk/identity-sum-spec.k
```

Expected result after a future machine-checking pass: `#Top` for the claims in `identity-sum-spec.k`.

## Test Recommendation

Do not remove tests. If the K claims are later machine-checked, focused in-domain tests for concrete identity entries, symbolic identity entries, and exact nested sums would be subsumed by PO1-PO6, but integration and broader summation tests should remain.

