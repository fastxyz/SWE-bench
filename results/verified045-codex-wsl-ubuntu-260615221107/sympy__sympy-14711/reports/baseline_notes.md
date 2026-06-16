# Baseline Notes

## Root Cause

`sum()` starts accumulation with the integer `0` when no explicit start value is
given. For `sum([N.x, 0 * N.x])`, Python therefore attempts `0 + N.x`, which
dispatches to `Vector.__radd__`. In `sympy.physics.vector.Vector`,
`__radd__` is aliased to `__add__`, and `__add__` immediately calls
`_check_vector(other)`. Since the accumulator is the scalar `0`, `_check_vector`
raises `TypeError('A Vector must be supplied')` before treating zero as the
additive identity.

## Files Changed

`repo/sympy/physics/vector/vector.py`

Added a narrow scalar-zero check at the start of `Vector.__add__`. When the
other operand is not already a `Vector` and compares equal to `0`, addition now
returns an equivalent `Vector` copy of `self`. This fixes both `0 + vector`
through the existing `__radd__ = __add__` alias and `vector + 0`, while keeping
the existing `_check_vector` behavior for nonzero non-vector operands.

## Assumptions and Alternatives Considered

I assumed the issue is limited to `sympy.physics.vector.Vector`, because the
reported import path and traceback point to `sympy/physics/vector/vector.py`.
The newer `sympy.vector` implementation has a separate zero-vector model and
was not changed.

I considered changing `_check_vector()` to coerce scalar zero to `Vector(0)`,
but rejected that because `_check_vector()` is used by dot, cross, outer
product, frame setters, and point helpers. Accepting scalar zero everywhere
would broaden APIs beyond additive identity handling and could mask invalid
arguments.

I also considered adding only a dedicated `__radd__` implementation for
`sum()`, but rejected that because `vector + 0` is the same additive-identity
case and `__sub__`/`__rsub__` also route through `__add__` after multiplying by
`-1`.
