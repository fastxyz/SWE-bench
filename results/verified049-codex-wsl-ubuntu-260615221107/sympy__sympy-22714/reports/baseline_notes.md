# Baseline Notes

## Root Cause

`Point.__new__` checks numeric coordinates with `im(a)` and then uses the
result in a Python truth test. When `S(...)` is called inside
`evaluate(False)`, `sympify` parses the string with evaluation disabled, and
`Function.__new__` also respects the global `evaluate` flag. As a result,
`im(Integer(1))` can remain as an unevaluated `im(1)` object instead of
becoming `0`. That unevaluated object is truthy, so real numeric coordinates
are incorrectly rejected as imaginary.

## Changed Files

`repo/sympy/geometry/point.py`

The imaginary-coordinate validation now calls `im(a, evaluate=True)`. This
keeps the existing validation behavior for numeric coordinates, including
rejecting genuinely complex numeric coordinates, but prevents the global
`evaluate(False)` context from making real coordinates look nonzero during the
validation probe.

## Assumptions and Rejected Alternatives

I assumed the intended behavior is that point coordinate validation should be
mathematical and should not depend on the ambient evaluation context. The
`evaluate` option for points controls coordinate simplification and float
rationalization; it should not disable the safety check that excludes complex
coordinates.

I considered changing parsing or `sympify`, but the parsed call is valid and
the failure comes from geometry validation using an unevaluated helper result in
a truth test. I also considered replacing the check with `im(a).is_zero`, but
that would change behavior for indeterminate numeric values because it only
rejects values known to have nonzero imaginary part. Forcing evaluation of
`im` is the smaller compatibility-preserving fix.
