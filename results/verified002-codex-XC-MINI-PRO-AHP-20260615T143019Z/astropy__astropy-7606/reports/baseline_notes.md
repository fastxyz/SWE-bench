# Baseline Notes

## Root Cause

`UnrecognizedUnit.__eq__` attempted to normalize every comparison target with
`Unit(other, parse_strict='silent')` before checking whether the result was
another `UnrecognizedUnit`. That normalization raises `TypeError` for `None`
and for other objects that cannot be converted to a unit, so `x == None` raised
instead of returning `False`.

The regular `UnitBase.__eq__` path already treats failed unit conversion as an
unequal comparison by catching `ValueError`, `UnitsError`, and `TypeError`.
`UnrecognizedUnit.__eq__` was missing that defensive handling.

## Files Changed

- `repo/astropy/units/core.py`: wrapped the `Unit(...)` conversion in
  `UnrecognizedUnit.__eq__` with the same conversion-failure handling used by
  `UnitBase.__eq__`, returning `False` when the other object is not unit-like.

## Assumptions and Alternatives

- I assumed equality comparison should not raise for unrelated objects, matching
  the issue text and the existing behavior of normal unit equality.
- I kept the existing comparison semantics for recognized units and unrecognized
  unit strings: only another `UnrecognizedUnit` with the same name compares
  equal.
- I considered special-casing only `None`, but rejected that because the same
  root cause applies to any object that `Unit(...)` cannot convert and because
  `UnitBase.__eq__` already establishes the broader conversion-failure pattern.
- I did not modify tests or run the test suite, per the benchmark constraints.
