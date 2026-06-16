# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal English clause | Intent entries | Verdict | Notes |
| --- | --- | --- | --- |
| `window-ref-forces-wrapper` | Intent 1, 2, 3, 4 | Pass | Captures the issue-backed selected annotation case. |
| `window-ref-produces-safe-sql-shape` | Intent 1, 2, 4 | Pass | Encodes the alias boundary required to avoid PostgreSQL's aggregate-over-window error. |
| `existing-trigger-still-wraps` | Intent 5 | Pass | Preserves previous wrapping behavior. |
| `no-trigger-remains-direct` | Intent 5 | Pass | Prevents over-wrapping when no documented reason exists. |
| Scope excludes direct `Aggregate(Window(...))` lifting | Ambiguous clause | Pass with boundary | The exclusion is explicit and recorded as Finding F2; it is not used to claim unsupported behavior is fixed. |
| Public compatibility unchanged | Intent 6 | Pass | Confirmed in `PUBLIC_COMPATIBILITY_AUDIT.md`. |

No fail entries were found. The only ambiguity is direct window expression
lifting, which is kept out of the proof and out of the V1 success claim.
