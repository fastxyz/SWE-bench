# Spec Audit

Status: constructed, not machine-checked.

| Formal Claim | Intent Obligation | Verdict | Notes |
| --- | --- | --- | --- |
| C-001 | I-001, I-002 | Pass | This is the exact `None` failure path in the issue: `Unit(None)` raises `TypeError`, but equality returns `False`. |
| C-002 | I-002 | Pass | Mirrors the existing `UnitBase.__eq__` failure policy for `ValueError`. |
| C-003 | I-002 | Pass | Mirrors the existing `UnitBase.__eq__` failure policy for `UnitsError`. |
| C-004 | I-003 | Pass | Preserves public same-name unknown-unit equality. |
| C-005 | I-003 | Pass | Preserves public different-name unknown-unit inequality. |
| C-006 | I-004 | Pass | Preserves the prior rule that only another same-name `UnrecognizedUnit` is equal. |
| C-007 | I-005 | Pass | Follows directly from unchanged `__ne__`. |
| FC-001 | I-006 | Pass | V1 changes only `UnrecognizedUnit.__eq__`; constructor behavior remains untouched. |
| FC-002 | I-006 | Pass | V1 does not alter operators, conversion, parsing, or signatures. |

No formal claim is candidate-derived without public or compatibility evidence.
No required behavior is marked fail or ambiguous.
