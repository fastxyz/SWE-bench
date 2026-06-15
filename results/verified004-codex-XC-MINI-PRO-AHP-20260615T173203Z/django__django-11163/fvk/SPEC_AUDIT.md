# Spec Audit

Status: pass, constructed not machine-checked.

| Formal statement | Intent source | Audit result | Notes |
| --- | --- | --- | --- |
| `MODEL-TO-DICT-EMPTY-FIELDS` returns empty result for `fields=[]`. | E-001, E-002 | Pass | Directly matches the issue. |
| `MODEL-TO-DICT-GENERAL` treats `fields=None` as no inclusion filter. | E-003 | Pass | "If provided" implies `None` is the omitted case. |
| `MODEL-TO-DICT-GENERAL` treats any provided list as an inclusion filter. | E-003 | Pass | Includes the empty list boundary. |
| `MODEL-TO-DICT-GENERAL` applies `exclude` after inclusion. | E-004 | Pass | Matches docstring precedence. |
| Read-log records only selected fields. | E-006 | Pass | Captures the public hint about not touching unrequested values. |
| Function signature and return shape unchanged. | E-007 | Pass | The source edit only changes an internal condition. |

No formal statement is derived solely from the V1 implementation's current
output. The current source is checked against the intent-derived contract.
