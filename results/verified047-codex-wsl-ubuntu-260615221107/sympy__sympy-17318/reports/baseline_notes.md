# Baseline Notes

## Root Cause

`sqrtdenest` reaches `_sqrt_match` while recursively inspecting square-root
arguments. For additive inputs such as `4 + I`, `_sqrt_match` treated the
argument as suitable for `split_surds` because each addend squared to a
rational value. That check was too broad: `split_surds` expects ordinary
square-root surds, not additive expressions with no square-root surd part or
with complex/non-positive squared terms.

`split_surds` then built an empty surd list for inputs like `4 + I` and passed
it to `_split_gcd`, which unconditionally indexed the first element. This caused
the reported `IndexError`. The same shared helper path also affected
`rad_rationalize`; when no square-root component could be split out, it could
continue transforming the same unsupported additive denominator instead of
returning unchanged.

## Files Changed

`repo/sympy/simplify/sqrtdenest.py`

- Tightened `_sqrt_match` so the `split_surds` fast path is used only when all
  squared addends are rational and positive. This prevents complex/non-positive
  cases such as `4 + I` from being handed to a helper intended for regular
  square-root surds.

`repo/sympy/simplify/radsimp.py`

- Updated `rad_rationalize` to return `(num, den)` unchanged when `split_surds`
  finds no rationalizable square-root component.
- Restricted `split_surds`' surd collection to `Pow` terms with exponent
  `S.Half`, matching the terms that the function can actually split into the
  square-root part.
- Made `_split_gcd` return a neutral split for an empty input list instead of
  indexing into it.

## Assumptions and Alternatives

I assumed the intended behavior for unsupported inputs is to leave them
unchanged rather than trying to rationalize complex units or higher roots in
these square-root-specific helpers. This matches the issue statement that an
expression that cannot be denested should be returned unchanged.

I considered fixing only `_sqrt_match`, which is enough for the direct
`sqrtdenest` traceback, but rejected that as too narrow because `split_surds`
is shared with the user-facing `rad_rationalize` path described in the public
issue notes. I also rejected catching the `IndexError`, since the failure comes
from an invalid helper precondition and the issue explicitly asks not to use
bare exception handling.
