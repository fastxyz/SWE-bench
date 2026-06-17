# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` commands were run.

## Claims

The formal claims are in `fvk/collect-factor-and-dimension-spec.k` and use the
mini semantics in `fvk/mini-unit-dimension.k`.

Claim 1 proves the issue instance abstraction:
`accelerationTime + velocity` under `withDimSystem` reaches
`ok(F1 + F2, accelerationTime)`.

Claim 2 proves the general accepted-addition family: when every remaining
addend is compatible with the first dimension under `withDimSystem`, collection
returns the sum of all factors and the first dimension.

Claim 3 proves the preserved error case: `length + time` under a dimension
system reaches `dimensionError(time, length)`.

Claim 4 proves the no-dimension-system fallback: `accelerationTime + velocity`
under `noDimSystem` reaches `dimensionError(velocity, accelerationTime)`.

## Proof Sketch

The mini semantics starts `collectAdd` by storing the first collected factor and
dimension in `collectAddLoop`.

For each remaining addend, the loop has two cases:

1. `compatibleDims(DS, D, D2)` is true. The loop adds the addend factor to the
   accumulator and keeps `D` unchanged.
2. `compatibleDims(DS, D, D2)` is false. The loop reaches
   `dimensionError(D2, D)`.

For `withDimSystem`, compatibility is direct equality or equal dependency maps.
The dependency rules map both `accelerationTime` and `velocity` to `dep(1, -1)`,
so the issue pair follows case 1. `length` maps to `dep(1, 0)` and `time` maps
to `dep(0, 1)`, so `length + time` follows case 2.

For `noDimSystem`, compatibility reduces to direct equality. Since
`accelerationTime` and `velocity` are unequal dimension expressions, the
fallback claim follows case 2.

The generalized claim follows by induction over `FDList`: the base `.FDList`
returns `ok(F, D)`, and the step case consumes one compatible `fd(F2, D2)`,
updates the accumulator to `F + F2`, and reuses the claim on the rest of the
list.

## Relation To V1 Code

The V1 source condition is:

```python
if dim != addend_dim and (
        dimension_system is None or
        not dimension_system.equivalent_dims(dim, addend_dim)):
    raise ValueError(...)
```

This exactly implements `compatibleDims` from the mini semantics:

- direct equality accepts immediately;
- a missing dimension system rejects unequal dimensions;
- an active dimension system accepts unequal dimensions only when
  `equivalent_dims` is true.

No further code change is justified by the proof obligations.

## Commands To Machine-Check Later

These commands are intentionally not run in this task:

```sh
kompile fvk/mini-unit-dimension.k --backend haskell
kast --backend haskell fvk/collect-factor-and-dimension-spec.k
kprove fvk/collect-factor-and-dimension-spec.k
```

Expected machine-check result after a successful future run: `#Top`.

## Residual Risk

This is a partial-correctness proof over a mini semantics. It verifies the
dimension-compatibility decision and factor accumulation for the `Add` branch.
It does not machine-check the full SymPy runtime, termination, performance, or
unrelated branches of `_collect_factor_and_dimension`.

No test-removal recommendation is made because the proof was not
machine-checked and the task forbids modifying tests.
