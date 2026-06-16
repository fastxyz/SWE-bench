# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent match | Result |
| --- | --- | --- |
| `GET-TZ-DISABLED` | Matches E10 and `TimezoneMixin.get_tzname()`: timezone conversion has no effect when `USE_TZ` is false. | PASS |
| `GET-TZ-CURRENT` | Matches E10 and existing behavior: absent `tzinfo` falls back to current timezone. | PASS |
| `GET-TZ-EXPLICIT` | Matches E1, E4, E6, and E7: explicit `tzinfo` overrides the current timezone. | PASS |
| `DATE-DISABLED` | Combines disabled timezone behavior with E9's cast-specific operation. | PASS |
| `DATE-CURRENT` | Preserves existing fallback while using the date cast operation. | PASS |
| `DATE-EXPLICIT` | Directly covers the reported `TruncDate(..., tzinfo=tz)` bug. | PASS |
| `TIME-DISABLED` | Combines disabled timezone behavior with E9's cast-specific operation. | PASS |
| `TIME-CURRENT` | Preserves existing fallback while using the time cast operation. | PASS |
| `TIME-EXPLICIT` | Directly covers the reported analogous `TruncTime(..., tzinfo=tz)` bug. | PASS |
| Params preserved | Matches E11 and the unchanged `return sql, lhs_params` shape. | PASS |
| Backend details abstracted | Matches E12: backend methods already own SQL rendering; this audit concerns the `tzname` argument. | PASS |

No formal-English obligation is candidate-derived without public intent
support. No obligation conflicts with the public issue or docs.

