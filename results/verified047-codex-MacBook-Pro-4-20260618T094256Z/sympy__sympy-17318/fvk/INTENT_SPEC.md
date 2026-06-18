# Intent Specification

Status: constructed, not machine-checked.

## Scope

This audit targets the V1 changes for issue `sympy__sympy-17318`:

- `sympy/simplify/sqrtdenest.py:_sqrt_match`
- `sympy/simplify/radsimp.py:split_surds`
- `sympy/simplify/radsimp.py:rad_rationalize`

The proof model covers the public issue paths and the directly touched helper
branches. It does not attempt to model all SymPy expression canonicalization or
all denesting algorithms.

## Intent-Only Obligations

O1. `sqrtdenest` must not raise `IndexError` when a nested radical contains an
expression such as `4 + I` that cannot be denested as a real square-root surd
sum.

O2. If such an expression cannot be denested, `sqrtdenest` should leave it
unchanged rather than turning helper failure into a user-visible exception.

O3. `_sqrt_match` should not call `split_surds` on an additive expression whose
terms include non-real or otherwise unsupported entries such as `I`; those are
not regular non-complex square-root surds.

O4. `split_surds` must not call `_split_gcd` with an empty list of surds. If an
additive expression has no supported square-root term, the helper must return a
well-shaped no-surd result.

O5. `rad_rationalize`, which is a documented user-facing helper, must not fail
with `IndexError` for denominators such as `4 + I`.

O6. `rad_rationalize` must not recurse forever when the denominator contains no
square-root surd to remove, for example `1 + cbrt(2)`.

O7. Existing in-domain square-root behavior remains a frame condition:
`rad_rationalize(1, sqrt(2) + I)` should still be handled by the square-root
path, and the documented `split_surds` example should remain in the supported
domain.

O8. The fix must not rely on bare exception catching. It should prevent invalid
helper calls at their source.

O9. Public signatures and return shapes must be preserved: `_sqrt_match`
continues to return a match list or `[]`, `split_surds` continues to return a
3-tuple, and `rad_rationalize` continues to return a numerator/denominator pair.

## Default-Domain Assumptions

DA1. The audited `split_surds` domain is the domain described by its docstring
and the public issue discussion: sums of regular, non-complex square-root terms
and rational/non-surd companions.

DA2. For unsupported inputs in best-effort simplification helpers, returning the
input unchanged is preferable to raising an internal helper exception.

DA3. The audit is partial correctness only. It proves the stated postconditions
for the modeled terminating branches; it does not prove global termination of
all SymPy simplification paths.
