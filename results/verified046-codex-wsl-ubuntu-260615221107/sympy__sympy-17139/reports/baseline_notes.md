# Baseline Notes

## Root Cause

`simplify(cos(x)**I)` reaches the Fu trigonometric simplification rule
`TR6`, which calls `_TR56` in `sympy/simplify/fu.py`. `_TR56` first checks
whether the exponent is negative with `rv.exp < 0`. That comparison is only
valid for ordered real values, so a complex exponent such as `I` raises
`TypeError: Invalid comparison of complex I` before the rule can decide that
the trigonometric power should be left unchanged.

The transformation performed by `_TR56` rewrites powers such as
`cos(x)**2` and `sin(x)**4` using Pythagorean identities. That rule only
applies to exponents known to be integers, and the later code already assumes
integer-like behavior when it checks evenness and divides the exponent by two.

## Changed Files

`repo/sympy/simplify/fu.py`

Added an early guard in `_TR56` that returns the original expression unless
`rv.exp.is_integer is True`. This prevents non-integer and complex exponents
from reaching ordered comparisons or parity checks. The existing negative and
maximum exponent checks were otherwise left in the same fuzzy-comparison style
so known integer symbolic exponents keep the surrounding behavior.

## Assumptions

The intended behavior for `cos(x)**I` is to leave the power unchanged during
this trigonometric identity rewrite, not to introduce a complex-power-specific
rewrite. This follows from `_TR56` being a helper for even integer power
identities.

I assumed hidden tests may exercise the same failure through `TR5`, `TR6`,
`TR15`, `TR16`, or `TR22`, all of which share `_TR56`. Fixing the shared
helper is therefore preferable to special-casing `TR6`.

## Alternatives Considered

One option was to check only `rv.exp.is_extended_real is False` before the
comparison. I rejected that because the rule still relies on integer parity,
so allowing arbitrary real non-integer exponents to proceed would not match
the identity being applied.

Another option was to require `rv.exp.is_Integer`, which would accept only
literal integer exponent objects. I rejected that as unnecessarily restrictive
because other parts of `fu.py` use assumption predicates like `is_integer` to
support symbolic integer exponents where possible.
