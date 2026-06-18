# Proof

Status: constructed, not machine-checked.

No K commands were executed. The commands below are the exact commands a later
environment would run to machine-check the constructed claims.

## Commands

```sh
cd fvk
kompile mini-python.k --backend haskell --main-module MINI-PYTHON --syntax-module MINI-PYTHON-SYNTAX
kprove point-scalar-mul-spec.k --definition mini-python-kompiled --spec-module POINT-SCALAR-MUL-SPEC
```

Expected result if the mini-semantics and claims are accepted by K:

```text
#Top
```

This expected result is not claimed as observed.

## Constructed Proof Sketch

`POINT-RMUL`:

1. `exprMul(scalar(F), point(CS))` checks priorities.
2. `priority(point(CS)) = 10001` and `priority(scalar(F)) = 10000`.
3. The dispatch rule routes to `pointRMul(scalar(F), point(CS))`.
4. `pointRMul` rewrites to `pointMul(point(CS), scalar(F))`.
5. `pointMul` rewrites to `point(scale(CS, F))`.

`POINT-RMUL-DIRECT` follows steps 4 and 5 directly.

`ISSUE-EXAMPLE`:

1. `issueLeft(A, scalar(F), B)` evaluates `exprMul(scalar(F), B)` before
   applying the `addTo(A)` continuation.
2. By `POINT-RMUL`, that multiplication reaches
   `point(scale(ListItem(X2) ListItem(Y2), F))`.
3. The `addTo` continuation then rewrites to coordinate-wise `addCoords` with
   the original left point.
4. `issueRight(A, scalar(F), B)` evaluates `pointMul(B, scalar(F))` and then
   the same `addTo(A)` continuation, reaching the same coordinate-wise target.

`RADD-FRAME`, `RSUB-FRAME`, and `RDIV-FRAME`:

The reflected `Expr`-left operations rewrite to symbolic expression forms,
matching the shape of `Expr.__add__`, `Expr.__sub__`, and `Expr.__div__` rather
than recursively calling the inherited `GeometryEntity` reflected methods.

`HIGHER-PRIORITY-FRAME`:

For a left operand with priority `10010`, the foreign-left dispatch rule fires
because `10010 > 10001`. This models the compatibility argument that V1's point
priority wins over plain `Expr` scalars but not over higher-priority arithmetic
families.

## Residual Risk

- The proof is constructed only; `kprove` was not run.
- The mini-semantics models the relevant dispatch and coordinate-wise scaling
  fragment, not the full Python or SymPy runtime.
- Integer coordinates/scalars abstract the structural property. Floating
  precision, SymPy simplification internals, and noncommutative scalar ordering
  are outside the mini-model.

## Test Recommendation

No test removal is recommended. Existing tests and any hidden tests should remain
until the emitted K commands are actually run and `kprove` returns `#Top`.
