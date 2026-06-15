# Intent Spec

Status: constructed, not machine-checked.

## Target

`repo/astropy/units/core.py`, specifically
`UnrecognizedUnit.__eq__` and its dependent `__ne__`.

## Intent-Only Obligations

I-001: For `x = u.Unit('asdf', parse_strict='silent')`, the expression
`x == None` must return `False`; it must not raise the `TypeError` emitted by
direct `Unit(None)` construction.

I-002: Equality on an `UnrecognizedUnit` should not propagate ordinary unit
conversion rejection failures from `Unit(other, parse_strict='silent')`.
Those targets are simply not equal to the unknown unit.

I-003: Two `UnrecognizedUnit` instances, or an unknown-unit string that
converts to one, compare equal exactly when their names match.

I-004: A recognized unit or numeric unit conversion result is not equal to an
`UnrecognizedUnit`.

I-005: `__ne__` remains the logical complement of `__eq__`.

I-006: The fix must not change direct `Unit(None)` behavior, unit parsing
behavior, public method signatures, or invalid arithmetic behavior for
`UnrecognizedUnit`.

## Default-Domain Assumption

The formal proof ranges over ordinary unit conversion outcomes: successful
conversion to a recognized unit, successful conversion to an unrecognized unit,
or the known conversion-rejection exceptions `ValueError`, `UnitsError`, and
`TypeError`. Unexpected internal bugs or deliberately hostile objects that
raise unrelated exceptions from their own formatting/conversion hooks are
outside this proof; catching those would be a broader API policy change.
