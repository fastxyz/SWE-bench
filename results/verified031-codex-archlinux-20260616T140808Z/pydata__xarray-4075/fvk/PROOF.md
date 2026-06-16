# PROOF.md

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

For the modeled reduction domain, if xarray has aligned the inputs and the
reducer is called with boolean data and boolean weights, V1 returns the integer
0/1 dot sum before any weighted mean division occurs. Therefore the reported
boolean-weight mean has denominator `2` instead of `True`, and the issue example
has mean `1.0`.

## Proof Sketch

1. The cast guard claim proves the branch condition:
   `needsCast(boolKind, boolKind) => true`, while the three mixed/non-boolean
   combinations rewrite to `false`.
2. The bool/bool reducer claim rewrites
   `reduceBoolBool(BS, WS)` to `dot01(BS, WS)` for equal-length lists.
   `dot01` is defined recursively as the integer sum of
   `boolToInt(B_i) * boolToInt(W_i)`.
3. For the issue denominator:
   `dot01([true, true, true], [true, true, false])`
   rewrites to `1*1 + 1*1 + 1*0 + 0 = 2`.
4. `sumOfWeightsBool` therefore rewrites to `SomeWeight(2)`, not to a boolean.
5. The numerator for data `[1, 1, 1]` and weights `[true, true, false]` is
   `1*1 + 1*1 + 1*0 = 2`.
6. `weightedMeanBoolWeights` rewrites to `Ratio(2, 2)`, representing the mean
   value `1`.

## Source Trace

- In `Weighted._sum_of_weights`, `mask = da.notnull()` creates a boolean data
  operand and `_reduce(mask, self.weights, ...)` is the denominator path.
- V1 adds the pre-dot guard in `Weighted._reduce`:
  `if da.dtype.kind == "b" and weights.dtype.kind == "b": da = da.astype(int)`.
- Because the cast happens before `dot`, the numeric count is still recoverable.
  Casting after `dot` would not prove PO-1 or PO-2 because the count could
  already have collapsed to `True`.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not executed in this task.

```sh
kompile fvk/mini-weighted.k --backend haskell
kast --backend haskell fvk/weighted-spec.k
kprove fvk/weighted-spec.k
```

Expected machine-check outcome: `kprove` returns `#Top` for all claims.

## Test Guidance

No tests were run and no test files were modified. Existing tests should be kept
until the K claims are machine-checked. Useful conventional tests, if a future
developer adds tests outside this benchmark constraint, would cover:

- boolean weights for `DataArray.weighted(...).mean()`;
- boolean weights for `sum_of_weights()`;
- boolean data with boolean weights for `.sum()`, exercising the shared
  `_reduce` obligation;
- a zero-boolean-weight denominator.

## Residual Risk

The proof is partial and constructed only. The mini semantics abstracts away
full xarray alignment, coordinates, dimensions, duck-array backend behavior, and
attrs, but it preserves the defect axis: boolean truth reduction versus integer
0/1 summation. Source inspection discharges the framed compatibility obligations
for unchanged APIs and mixed dtype paths.
