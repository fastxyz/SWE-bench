# Proof

Status: constructed, not machine-checked.

## What Is Proved

For every in-domain `PandasMultiIndexingAdapter` with a named MultiIndex level:

- if `dtype is None`, `__array__` returns the pandas level values cast to
  `self.dtype`;
- if an explicit dtype is supplied, `__array__` returns the pandas level values
  cast to that explicit dtype; and
- for adapters produced from stacked xarray coordinate variables, default
  `.values` materialization has the original coordinate dtype recorded by xarray.

For adapters with `level is None`, V1 preserves delegation to the base pandas
index adapter.

## Proof Sketch

The method has one conditional and no loops.

1. Start from a call to `__array__(adapter(level=L, dtype=D), requested=None)`.
2. The first statement tests `dtype is None` and assigns `dtype = self.dtype`,
   so the effective dtype is `D`. This discharges `PO3`.
3. The second conditional sees `self.level is not None` and enters the level
   branch.
4. The branch obtains the same pandas level values as the pre-V1 code:
   `self.array.get_level_values(self.level).values`.
5. V1 wraps those values in `np.asarray(..., dtype=D)`, so the result dtype is
   the stored adapter dtype for castable values. This discharges `PO4`.
6. In the stacked-coordinate producer path, `D` is the original coordinate dtype
   recorded in `PandasMultiIndex.level_coords_dtype` and passed into
   `PandasMultiIndexingAdapter`. This composes `PO2` with `PO3` and `PO4`,
   discharging the reported issue property.
7. If an explicit dtype is supplied, step 2 does not change it, so the level
   branch casts to the explicit dtype. This discharges `PO5`.
8. If `self.level is None`, the method skips the level branch and returns
   `super().__array__(dtype)`, preserving the previous non-level behavior and
   discharging `PO7`.

## K Claims

The formal claims are in `pandas-multi-indexing-adapter-spec.k`:

- `MI-ARRAY-DEFAULT-LEVEL-DTYPE`
- `MI-ARRAY-EXPLICIT-DTYPE`
- `STACKED-LEVEL-VALUES-DTYPE`
- `MI-ARRAY-NONLEVEL-DELEGATES`

There are no loop circularities because the audited method has no loop or
recursion.

## Residual Risk

This proof is partial correctness over the modeled conversion path. It does not
prove termination, real pandas internals, or real NumPy cast semantics. Those
are trusted boundaries for this FVK run because execution and K tooling are
forbidden.

## Machine-Check Commands

These commands are not run in this environment. They are the commands to run
later to turn this constructed proof into a machine-checked one:

```sh
cd fvk
kompile mini-python-indexing.k --backend haskell
kast --backend haskell pandas-multi-indexing-adapter-spec.k
kprove pandas-multi-indexing-adapter-spec.k
```

Expected machine-check result after the fragment is accepted by K: `#Top` for
all claims.

## Test Redundancy

No test files were read or modified for this benchmark. Any future public unit
test that checks only the in-domain dtype equality for a stacked castable level
coordinate would be subsumed by the proof after machine checking. Tests should
not be removed based on this constructed proof alone.

