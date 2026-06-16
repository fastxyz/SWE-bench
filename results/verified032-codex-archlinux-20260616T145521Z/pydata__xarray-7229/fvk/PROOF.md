# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Contract

For all in-domain `COND`, `X`, and `Y`, the V1
`where(cond, x, y, keep_attrs=True)` branch returns the same value result as
`duck_array_ops.where(COND, X, Y)` while assigning attrs according to `X`:

- top-level attrs are `attrs(X)`;
- Dataset data variable attrs are copied from matching variables in Dataset `X`,
  or from `attrs(X)` when `X` is not a Dataset;
- coordinate attrs are produced by coordinate-variable merge with `X` first,
  then `COND`, then `Y`, so data attrs from `X` never overwrite coordinate attrs;
- scalar `X` has empty attrs.

## Mini-Semantics

The proof uses a property-complete mini-model for attrs propagation:

```k
module MINI-XARRAY
  imports BOOL
  imports MAP

  syntax Obj ::= scalar | obj(Map, Map, Map)
  // obj(topAttrs, coordAttrsByName, dataVarAttrsByName)
  syntax Result ::= result(Value, Map, Map, Map)
  // result(value, topAttrs, dataVarAttrsByName, coordAttrsByName)

  syntax Value ::= whereValue(Obj, Obj, Obj) [function]
  syntax Map ::= attrsOf(Obj) [function]
  syntax Map ::= dataAttrsFromX(Obj, Set) [function]
  syntax Map ::= coordAttrsOverride(Obj, Obj, Obj) [function]
  syntax Set ::= resultDataVars(Obj, Obj, Obj) [function]

  rule attrsOf(scalar) => .Map
  rule attrsOf(obj(A, _C, _D)) => A

  syntax Result ::= whereKeepAttrsTrue(Obj, Obj, Obj) [function]
  rule whereKeepAttrsTrue(COND, X, Y)
    => result(
         whereValue(COND, X, Y),
         attrsOf(X),
         dataAttrsFromX(X, resultDataVars(X, COND, Y)),
         coordAttrsOverride(X, COND, Y)
       )
endmodule
```

The abstraction intentionally does not model array arithmetic, dask execution,
or alignment internals; those are unchanged xarray responsibilities. It does
model the discriminating property: top attrs, data-variable attrs, and coordinate
attrs are separate maps.

## Claim

```k
module XARRAY-WHERE-SPEC
  imports MINI-XARRAY

  // SPEC-PROVENANCE:
  // - problem: "Coordinate attributes should be preserved." => coord attrs are
  //   selected from coordinate variables, not data attrs.
  // - docstring: "If True, keep the attrs of `x`." => top/data attrs winner is X.
  // - public hint: scalar X must not select attrs[1] from Y.
  claim
    <k> whereKeepAttrsTrue(COND, X, Y)
     => result(
          whereValue(COND, X, Y),
          attrsOf(X),
          dataAttrsFromX(X, resultDataVars(X, COND, Y)),
          coordAttrsOverride(X, COND, Y)
        )
    </k>
endmodule
```

## Constructed Proof

1. Enter the `keep_attrs is True` branch. This is the only branch under audit;
   all non-true branches are framed unchanged by O6.
2. Bind `x_attrs := attrsOf(X)`. By the mini-semantics, `attrsOf(scalar) = .Map`,
   discharging O5 for scalar `X`.
3. Symbolically execute the `apply_ufunc` call with argument order `(X, COND, Y)`
   and `keep_attrs=True`.
4. `apply_ufunc` normalizes boolean `keep_attrs=True` to the existing
   `"override"` strategy. Because `X` is first, DataArray/Dataset top attrs and
   coordinate merges have `X` as the override winner when `X` supplies the
   relevant object. This discharges O2 and O4.
5. The local wrapper body rewrites `func(X, COND, Y)` to
   `duck_array_ops.where(COND, X, Y)`, discharging O1 despite the internal
   argument reorder.
6. After `apply_ufunc` returns, V1 assigns `result.attrs = attrsOf(X)`. This is
   idempotent when `X` was already the first labeled input and corrective when
   `X` is scalar or mixed with Dataset output. O2 and O5 remain discharged.
7. If the result has `data_vars`, V1 iterates every result variable. If `X` has
   `data_vars`, it assigns matching `X[name].attrs`; otherwise it assigns
   `attrsOf(X)`. This discharges O3.
8. No code path in steps 6-7 writes `result.coords[...]`. Thus coordinate attrs
   produced by the `X`-first coordinate merge are not overwritten by top/data
   attrs. O4 remains discharged.
9. No signature or callsite-visible parameter changes occur. O7 is discharged.

There are no loops or recursion in the changed branch, so no circularity claim is
required. The proof is partial correctness: if the existing xarray machinery
returns, the attrs postconditions above hold.

## Reproduce The Machine Check

These are the commands that would be used to machine-check the K files emitted
with this audit. They were not run in this session.

```sh
kompile fvk/mini-xarray.k --backend haskell
kast --backend haskell fvk/xarray-where-spec.k
kprove fvk/xarray-where-spec.k
```

Expected machine-check result for a faithful K model: `#Top`.

## Test Guidance

Conditioned on a successful machine check, public tests that assert
`xr.where(cond, x, y, keep_attrs=True)` copies attrs from `x` and not from scalar
`x` are covered by O2 and O5. Coordinate-attrs regression tests are covered by
O4. Integration tests for alignment, dask arrays, Dataset joins, and dtype/value
behavior should be kept because the mini-model abstracts those concerns.
