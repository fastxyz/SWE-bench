# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Non-Integer Exponents Exit Before Unsafe Operations

For any visited `Pow` with target base function `f`, if
`rv.exp.is_integer is not True`, `_TR56` returns `rv` before evaluating:

- `rv.exp < 0`;
- `rv.exp > max`;
- `rv.exp % 2`;
- `perfect_power(rv.exp)`.

This obligation directly covers `rv.exp == I`.

## PO-2: Negative and Too-Large Integer Exponents Are Unchanged

For exponents known to be integers, if `(rv.exp < 0) == True` or
`(rv.exp > max) == True`, `_TR56` returns `rv`.

This preserves the documented examples `sin(x)**-2` and `sin(x)**10` with
`max=4`.

## PO-3: Exponent `2` Rewrites to the Base Pythagorean Identity

For a target power with exponent `2`, `_TR56` returns `h(g(arg)**2)`.

This covers `TR5(sin(x)**2)` and `TR6(cos(x)**2)`.

## PO-4: Exponent `4` Rewrites as the Square of the Base Identity

For a target power with exponent `4`, `_TR56` returns `h(g(arg)**2)**2`.

This preserves the documented `TR5` and `TR6` fourth-power examples.

## PO-5: `pow=False` Rewrites Only Even Integer Exponents Within `max`

For `pow=False`, a target power with known nonnegative integer exponent within
`max` is rewritten only when the exponent is even. Odd integer exponents are
unchanged. The rewrite exponent is `rv.exp//2`.

This covers the documented contrast between `sin(x)**3` unchanged and
`sin(x)**6` rewritten when `max=6`.

## PO-6: `pow=True` Rewrites Only Concrete Powers of Two

For `pow=True`, after the non-integer, negative, too-large, `2`, and `4` cases:

- non-concrete symbolic integer exponents are unchanged before `perfect_power`;
- concrete integer exponents are passed to `perfect_power`;
- the rewrite is allowed only when `perfect_power(rv.exp)` succeeds with base
  `2`;
- all concrete non-powers of two, including `6` and `9`, are unchanged.

This obligation is the V2 improvement over V1.

## PO-7: Traversal Frame

`bottom_up(rv, _f)` may apply the local decision to nested subexpressions, but
the local proof is framed over traversal: each visited node satisfies PO-1
through PO-6 independently, and non-target nodes are returned unchanged by `_f`.

## PO-8: Public Compatibility

The fix must not change the signature or expected return category of `_TR56` or
its public wrappers `TR5`, `TR6`, `TR15`, `TR16`, and `TR22`.
