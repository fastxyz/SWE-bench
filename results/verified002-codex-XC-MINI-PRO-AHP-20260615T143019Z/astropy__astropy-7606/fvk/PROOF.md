# Constructed Proof

Status: constructed, not machine-checked.

## Target

`UnrecognizedUnit.__eq__(self, other)` in
`repo/astropy/units/core.py`.

## Claim

For every `UnrecognizedUnit` name `S` and every modeled conversion outcome of
`Unit(other, parse_strict='silent')`, equality returns the specified boolean
without propagating `ValueError`, `UnitsError`, or `TypeError`.

No loops or recursion occur, so no circularity or loop invariant is needed.

## Symbolic Proof

Start in `UnrecognizedUnit.__eq__` with `self.name = S`.

Case 1: `Unit(other, parse_strict='silent')` returns `UnrecognizedUnit(T)`.
The `try` body assigns that value to `other`. The return expression evaluates
`isinstance(other, UnrecognizedUnit)` to `True`, then returns `S == T`.
This discharges PO-002 when `S == T` and PO-003 when `S != T`.

Case 2: conversion returns a recognized unit value. The `try` body assigns it
to `other`. The return expression evaluates
`isinstance(other, UnrecognizedUnit)` to `False`; Python `and` short-circuits,
so the method returns `False`. This discharges PO-004.

Case 3: conversion raises `ValueError`, `UnitsError`, or `TypeError`. The V1
`except (ValueError, UnitsError, TypeError)` handler catches the exception and
returns `False`. The original `None` failure is the `TypeError` subcase. This
discharges PO-005 and resolves F-001 and F-002.

For `__ne__`, the source remains `return not (self == other)`. By substitution
from the equality cases above, inequality is the boolean complement for the
same conversion outcome. This discharges PO-006.

Frame conditions: V1 edits no constructor branch, no parser branch, no method
signature, and no operator assignment. Therefore direct `Unit(None)` still
raises when called directly, and invalid arithmetic on an `UnrecognizedUnit`
still follows `_unrecognized_operator`. This discharges PO-007 and PO-008.

## K Artifacts

The constructed K core is:

- `fvk/mini-python-unit-eq.k`
- `fvk/unrecognized-unit-eq-spec.k`

The K model abstracts conversion into `Conv` values and proves the return value
for each conversion class.

Commands to run later, not executed here:

```sh
cd fvk
kompile mini-python-unit-eq.k --backend haskell
kast --backend haskell unrecognized-unit-eq-spec.k
kprove unrecognized-unit-eq-spec.k
```

Expected result after a successful machine check: `#Top`.

## Residual Risk

This is a partial-correctness proof over a small model of the equality method,
not a full Python semantics. It does not prove behavior for deliberately
hostile objects or unrelated unexpected internal exceptions outside
`ValueError`, `UnitsError`, and `TypeError`. F-004 records why V1 does not
broaden to `except Exception`.

## Test Recommendation

Do not delete any tests. Machine-checking was not run, and the benchmark
forbids modifying tests. A useful future test would mirror the issue directly:
an `UnrecognizedUnit` compared with `None` should be `False` and `!= None`
should be `True`.
