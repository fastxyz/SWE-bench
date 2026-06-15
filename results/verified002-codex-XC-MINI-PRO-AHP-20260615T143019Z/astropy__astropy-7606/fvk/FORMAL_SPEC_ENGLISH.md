# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the K claims in
`fvk/unrecognized-unit-eq-spec.k`.

## Claims

C-001: If equality compares an `UnrecognizedUnit` with a target whose
`Unit(..., parse_strict='silent')` conversion raises `TypeError`, equality
returns `False`.

C-002: If that conversion raises `ValueError`, equality returns `False`.

C-003: If that conversion raises `UnitsError`, equality returns `False`.

C-004: If that conversion returns another `UnrecognizedUnit` with the same
name as `self.name`, equality returns `True`.

C-005: If that conversion returns another `UnrecognizedUnit` with a different
name, equality returns `False`.

C-006: If that conversion returns a recognized unit value rather than an
`UnrecognizedUnit`, equality returns `False`.

C-007: For a `TypeError` conversion failure, `__ne__` returns `True` because
it is the complement of `__eq__`. The same complement reasoning applies to the
other conversion classes by the source definition `return not (self == other)`.

## Frame Conditions

FC-001: No claim changes direct `Unit(None)` construction; the constructor can
still raise `TypeError` when called directly.

FC-002: No claim changes `UnrecognizedUnit` arithmetic, ordering, conversion,
or method signatures.
