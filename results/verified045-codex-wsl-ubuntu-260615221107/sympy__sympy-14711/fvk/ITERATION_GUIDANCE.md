# Iteration Guidance

Status: V1 is confirmed unchanged by the FVK audit.

## Decision

Keep the V1 source change:

```python
if not isinstance(other, Vector) and other == 0:
    return Vector(self.args + [])
```

No V2 source edit is justified. The branch is narrow enough to discharge the
scalar-zero obligations and leaves vector operands and nonzero invalid operands
on their original paths.

## Guidance for a Future Code/Test Pass

1. Add or keep a public regression test for `sum([N.x, 0 * N.x]) == N.x`.
2. Add or keep coverage for `N.x + 0`, `0 + N.x`, and `N.x + 1` raising
   `TypeError`.
3. Do not broaden `_check_vector()` unless a separate public issue requires
   scalar zero to be accepted by dot, cross, outer product, frame setters, or
   point setters.
4. Machine-check the generated K artifacts when an execution environment with K
   is available.

## UltimatePowers-Style Clarification If Needed

No clarification is required for the current issue. If future requirements ask
about dyadic addition or the newer `sympy.vector` subsystem, treat those as
separate intent scopes because this issue's traceback identifies only
`sympy.physics.vector.Vector.__add__`.
