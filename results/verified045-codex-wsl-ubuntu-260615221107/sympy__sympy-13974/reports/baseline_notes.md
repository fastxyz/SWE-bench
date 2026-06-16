# Baseline Notes

## Root Cause

`tensor_product_simp` treated `Pow` expressions by simplifying only the base and
then reapplying the exponent. When a product of identical `TensorProduct`
objects was canonicalized as a power, such as `TensorProduct(1, Pauli(3))**2`,
the exponent stayed outside the tensor product. As a result, the component
expressions never received the exponent, so existing simplifications like
`Pauli(3)**2 -> 1` could not run.

The same gap affected `expand(tensorproduct=True)`: a `Pow` node did not know
how to delegate tensor-product expansion to a `TensorProduct` base, so
`TensorProduct(...)**n` was left unchanged.

## Files Changed

`repo/sympy/physics/quantum/tensorproduct.py`

- Added `TensorProduct._eval_expand_tensorproduct_pow`, which applies an
  exponent to each tensor-product argument and rebuilds the tensor product.
- Added `tensor_product_simp_Pow`, mirroring the existing `Mul` helper, so
  powers whose bases simplify to a `TensorProduct` become
  `TensorProduct(arg1**exp, arg2**exp, ...)`.
- Updated `tensor_product_simp` to use the new `Pow` helper.
- Adjusted the nearby docstring so it no longer says powers of tensor products
  are unsupported by the simplifier.

`repo/sympy/core/power.py`

- Added a narrow `_eval_expand_tensorproduct` hook for `Pow`. It only delegates
  when the base object advertises `_eval_expand_tensorproduct_pow`; otherwise it
  preserves existing `Pow` behavior. This lets `expand(tensorproduct=True)` use
  the tensor-product-specific power rule without making ordinary power
  construction evaluate differently.

## Assumptions and Alternatives

I assumed the intended rule is the one described in the issue hint:
`TensorProduct(a, b, ...)**n` should simplify to
`TensorProduct(a**n, b**n, ...)` when tensor-product simplification or expansion
is explicitly requested.

I treated the rule as an explicit tensor-product simplification/expansion rule,
not as a general automatic evaluation rule for `TensorProduct.__pow__`. Adding
`TensorProduct._eval_power` would also fix the examples, but it would change
ordinary construction of `TensorProduct(...)**n` even when the caller did not
ask for expansion or simplification.

I did not add special handling for Pauli objects. Their power simplification
already exists; the bug was that tensor-product powers prevented those
component-level simplifications from being reached.

No tests or project code were run, in accordance with the task constraints.
