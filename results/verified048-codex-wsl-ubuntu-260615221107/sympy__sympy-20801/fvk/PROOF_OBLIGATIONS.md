# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - SymPy Boolean operands are never equal to Floats

Claim: For every Float self value `F` and every operand `B` such that `isinstance(B, Boolean)` before sympification, `Float.__eq__(F, B)` returns `False`.

Why this is required: E1-E4 require `S(0.0) == S.false` to be `False`, and the existing nonzero Float Boolean guard already encoded the same distinction for other Float values.

V1 discharge: the first executable branch in `Float.__eq__` is now:

```python
if isinstance(other, Boolean):
    return False
```

This branch precedes `_sympify(other)` and the zero-Float shortcut.

## PO2 - Native Python `False` remains outside the early SymPy-Boolean guard

Claim: A native `False` operand is not an instance of SymPy `Boolean` before sympification, so it does not take PO1's early return.

Why this is required: E5 shows public integer equality distinguishes native Python booleans from SymPy Boolean atoms. The issue names `S.false`, not native `False`.

V1 discharge: the guard tests `isinstance(other, Boolean)`, not `isinstance(other, bool)`. Native `False` proceeds to the pre-existing `_sympify` and zero shortcut path.

## PO3 - Numeric and non-Boolean comparison branches are framed

Claim: For operands that are not already SymPy Booleans, V1 reaches the same `_sympify`, zero-Float, `NumberSymbol`, `Float`, `Rational`, `Number`, and final non-Number branches as before.

Why this is required: the public issue is only about the Boolean/numeric confusion, so unrelated Float equality semantics should remain unchanged.

V1 discharge: the only added branch is before `_sympify` and fires only for already-SymPy Boolean operands.

## PO4 - Reverse comparison is already false

Claim: `S.false == Float(0.0)` remains `False`.

Why this is required: E2 reports that this direction already returns `False`; the fix should align the forward direction with it.

V1 discharge: V1 does not edit `BooleanAtom`, `Boolean`, or `Basic` equality. The reverse path remains unchanged.

## PO5 - Unsympifiable operands keep `NotImplemented`

Claim: If an operand is not an already-SymPy Boolean and `_sympify(other)` raises `SympifyError`, `Float.__eq__` returns `NotImplemented` as before.

Why this is required: the added guard must not change unrelated dispatch fallback behavior.

V1 discharge: the existing `try`/`except SympifyError: return NotImplemented` block is unchanged and remains reachable for non-Boolean operands.

## PO6 - No machine-check or test execution claimed

Claim: The proof is constructed only and all test-removal recommendations are conditional.

Why this is required: the task forbids tests, Python execution, and K tooling.

V1 discharge: artifacts include exact commands but mark them not run.

## K Claims

The corresponding K claims are in `fvk/float-eq-spec.k`:

- `sympy-false-zero-float`
- `sympy-false-nonzero-float`
- `native-false-zero-frame`
- `numeric-zero-frame`
- `unsympifiable-frame`

Exact commands that would be used outside this constrained task:

```sh
cd fvk
kompile mini-sympy-eq.k --backend haskell
kast --backend haskell float-eq-spec.k
kprove float-eq-spec.k
```
