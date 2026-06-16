# Intent Spec

Status: constructed from public evidence only. Current implementation behavior
is treated as an observation to audit, not as the expected behavior.

## Required Behavior

1. `sum([N.x, 0 * N.x])` for a `sympy.physics.vector.ReferenceFrame` basis
   vector must complete without `TypeError` and produce a vector equal to
   `N.x`.
2. Scalar zero is the additive identity for `sympy.physics.vector.Vector`
   addition. This includes `0 + vector`, because Python `sum()` starts with
   scalar `0`, and `vector + 0`, because the same additive identity is
   symmetric for this operator.
3. Vector plus vector behavior remains the existing vector combination:
   the resulting `Vector` is built from the concatenated component lists and
   normalized by the `Vector` constructor.
4. Nonzero non-vector operands remain invalid for vector addition and must
   continue to raise `TypeError('A Vector must be supplied')`.
5. The scope is `sympy.physics.vector.Vector`. The public issue and traceback
   point to `sympy/physics/vector/vector.py`, not the newer `sympy.vector`
   subsystem and not `Dyadic`.

## Frame Conditions

- Do not change public method signatures.
- Do not modify `_check_vector()` in a way that would allow scalar zero in
  dot, cross, outer product, frame setters, point setters, or other non-add
  vector APIs.
- Do not modify tests in this benchmark phase.

## Default-Domain Assumptions

- Python `sum(iterable)` uses integer `0` as the default start value.
- Python binary addition with `0 + vector` dispatches to the vector's reflected
  addition when integer addition cannot handle the vector operand.
- SymPy exact scalar zero values compare equal to Python integer `0`.
