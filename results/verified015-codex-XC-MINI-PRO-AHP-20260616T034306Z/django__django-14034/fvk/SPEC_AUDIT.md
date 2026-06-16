# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent clause | Result | Notes |
| --- | --- | --- | --- |
| C1 | I1, I2, I3 | Pass | Separates parent required state from child subfield required state. |
| C2 | I1 | Pass | Captures the reported HTML `required` bug for partial-required fields. |
| C3 | I2 | Pass | Keeps default `require_all_fields=True` behavior unchanged. |
| C4 | I3 | Pass | Keeps optional parent fields skippable in browser rendering. |
| C5 | I4 | Pass | Confirms validation was intentionally left out of the proof target. |
| Compatibility | I5 | Pass | No signature changes or new required override methods. |

No formal clause is candidate-only or legacy-only. The only preserved legacy
behavior, required-all rendering, is supported by visible public tests and does
not conflict with the issue's partial-required intent.

