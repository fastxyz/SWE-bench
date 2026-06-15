# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | V1 Discharge |
| --- | --- | --- | --- |
| PO-001 | The spec domain covers `UnrecognizedUnit.__eq__` for ordinary unit conversion outcomes: recognized unit, unrecognized unit, and known conversion rejection exceptions. | E-001, E-002, E-003 | The formal model enumerates these outcomes in `Conv`. |
| PO-002 | Same-name unknown-unit comparison returns `True`. | E-004 | The conversion succeeds, `isinstance(other, UnrecognizedUnit)` is true, and names match. |
| PO-003 | Different-name unknown-unit comparison returns `False`. | E-004 | The conversion succeeds, `isinstance` is true, and names do not match. |
| PO-004 | Recognized-unit comparison returns `False`. | E-003, prior source semantics | The conversion succeeds but `isinstance(other, UnrecognizedUnit)` is false. |
| PO-005 | Conversion failure with `ValueError`, `UnitsError`, or `TypeError` returns `False` and does not escape. | E-001, E-002, E-003 | V1 catches exactly those exceptions and returns `False`. |
| PO-006 | `__ne__` remains the complement of `__eq__`. | Source definition | V1 leaves `return not (self == other)` unchanged. |
| PO-007 | No direct constructor behavior changes, including `Unit(None)`. | E-005 | V1 catches only inside `UnrecognizedUnit.__eq__`; `_UnitMetaClass.__call__` is unchanged. |
| PO-008 | No public API or operator compatibility regression. | E-004, E-005, compatibility audit | V1 changes no signatures and no operator assignments. |

All obligations are discharged by source inspection and the constructed K
claims. None required an additional source edit beyond V1.
