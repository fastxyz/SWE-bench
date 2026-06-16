# Baseline Notes

## Root cause

`Complement(A, B)` delegates simplification to `B._complement(A)`. When `A`
was a `FiniteSet` and `B.contains(element)` was undecidable, the generic
`Set._complement` path treated every element that was not definitely contained
as an ordinary surviving element. That is valid for elements definitely outside
`B`, but it is too strong for symbolic elements: `x notin Interval(-10, 10)` is
not known merely because `Interval(-10, 10).contains(x)` returns a symbolic
condition.

The complex-region example had a second cause. `ComplexRegion._contains` used a
Python truth test on a SymPy `And` built from coordinate containment checks. For
symbolic coordinates this should remain a symbolic membership condition, not a
definite `True`.

Finite-set subtraction between symbolic finite sets had a related conservative
simplification gap: after removing an element that appeared syntactically in both
sets, the subtrahend could lose that element even though it might still equal a
remaining symbolic minuend element.

## Changed files

`repo/sympy/sets/sets.py`

- Updated the generic finite-set branch in `Set._complement` to split finite
  elements into three cases: definitely contained, definitely not contained, and
  unknown. Definitely contained elements are removed; definitely-not-contained
  elements remain as a `FiniteSet`; unknown elements remain under an unevaluated
  `Complement`.
- Tightened the finite-minus-finite symbolic case so syntactically shared
  symbolic elements are still kept in the subtrahend when they may equal a
  remaining symbolic element.

`repo/sympy/sets/fancysets.py`

- Updated `ComplexRegion._contains` to use public `contains` results for each
  coordinate and return `S.true`, `S.false`, or a symbolic `Or` of possible
  region-membership conditions. This prevents symbolic complex membership from
  being collapsed to Python `True`.

## Assumptions and alternatives

- I assumed the correct behavior is conservative simplification: remove only
  elements whose membership in the subtrahend is definitely true, keep elements
  definitely outside, and leave undecidable elements in an explicit complement.
- I rejected returning the original unevaluated `Complement(A, B)` for every
  mixed finite set because the existing code intentionally removes known numeric
  members, and the issue expects that behavior for `2 in Interval(-10, 10)`.
- I rejected treating all non-`True` membership results as outside the
  subtrahend, since that is the behavior that produced `{x, y}` instead of
  `{x, y} \ Interval(-10, 10)`.
- I did not run tests or project code, per the benchmark instruction that this
  session has no execution environment.
