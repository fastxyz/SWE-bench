# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "Unit equality comparison with None raises TypeError for UnrecognizedUnit" | Treat the displayed traceback as the bug, not intended behavior. | Encoded by PO-005 and claim `raises(typeError) => false`. |
| E-002 | prompt | "`x == None  # Should be False`" | Equality with `None` on an unknown unit returns `False`. | Encoded. |
| E-003 | prompt hint | "`==` should never fail" | Known unit-conversion rejection failures during equality must not escape. | Encoded for `ValueError`, `UnitsError`, and `TypeError`. |
| E-004 | source implementation | `UnitBase.__eq__` catches `(ValueError, UnitsError, TypeError)` and returns `False`. | Use the same compatibility pattern for `UnrecognizedUnit.__eq__`. | Encoded as implementation-compatible support, not sole intent. |
| E-005 | public test | `test_unknown_unit3` asserts same unknown unit names compare equal and different names compare unequal. | Preserve name-based `UnrecognizedUnit` equality. | Encoded by PO-002 and PO-003. |
| E-006 | public test | `test_unknown_unit3` expects direct `u.Unit(None)` to raise `TypeError`. | Do not change direct constructor semantics. | Frame condition PO-008. |
| E-007 | public test | `test_compare_with_none` checks normal units do not raise for `u.m == None`. | Keep unknown-unit equality aligned with normal-unit equality. | Encoded by conversion-failure contract. |
