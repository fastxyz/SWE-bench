# FVK Findings

Status: constructed, not machine-checked.

## Findings

F-001: Resolved code bug: `UnrecognizedUnit == None` propagated `TypeError`.

- Input: `x = u.Unit('asdf', parse_strict='silent')`; compare `x == None`.
- Observed before V1: `Unit(None)` raised `TypeError("None is not a valid Unit")`
  through `UnrecognizedUnit.__eq__`.
- Expected: `False`, per the prompt.
- V1 status: fixed by catching `TypeError` around the conversion in
  `UnrecognizedUnit.__eq__` and returning `False`.
- Related proof obligations: PO-001, PO-005.

F-002: Resolved family bug: ordinary conversion rejection failures during
unknown-unit equality should be unequal, not exceptional.

- Input class: any comparison target for which
  `Unit(other, parse_strict='silent')` rejects with `ValueError`,
  `UnitsError`, or `TypeError`.
- Observed before V1: at least `TypeError` for `None` escaped; the same
  missing guard applied to other known conversion failures.
- Expected: `False`, matching normal `UnitBase.__eq__` behavior.
- V1 status: fixed for all three known conversion-failure classes.
- Related proof obligations: PO-004, PO-005.

F-003: Preserved intended behavior: same-name and different-name
`UnrecognizedUnit` equality is unchanged.

- Input: `Unit("FOO", parse_strict='silent') == Unit("FOO",
  parse_strict='silent')`.
- Expected and V1 behavior by inspection: `True`.
- Input: `Unit("FOO", parse_strict='silent') == Unit("BAR",
  parse_strict='silent')`.
- Expected and V1 behavior by inspection: `False`.
- Related proof obligations: PO-002, PO-003.

F-004: No additional code change justified for arbitrary unexpected exceptions.

- Input class considered: objects or internal parser bugs that raise exceptions
  outside `ValueError`, `UnitsError`, or `TypeError` while being converted or
  formatted.
- Public evidence: the issue's concrete failure is `TypeError`; existing
  `UnitBase.__eq__` catches exactly `(ValueError, UnitsError, TypeError)`.
- Decision: do not broaden V1 to `except Exception`, because that would hide
  unrelated internal errors and diverge from the established equality pattern.
- Related proof obligations: PO-001, PO-008.

F-005: No compatibility issue found.

- Changed symbol: `UnrecognizedUnit.__eq__(self, other)`.
- Observed by source inspection: signature unchanged; `__ne__` unchanged;
  direct `Unit(None)` branch unchanged; arithmetic/operator behavior unchanged.
- Related proof obligations: PO-006, PO-007, PO-008.

## Proof-Derived Findings

No open proof-derived code bug remains in the modeled domain. The proof is
constructed, not machine-checked, so no test deletion is recommended.
