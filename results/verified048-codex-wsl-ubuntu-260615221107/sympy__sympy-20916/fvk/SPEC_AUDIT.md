# Spec Audit

| Formal English item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | Intent 1, 2, 3 | Pass | Captures the issue's required Unicode Greek trailing-digit behavior. |
| 2 | Intent 1, 2 | Pass | Covers the motivating `ω0` case. |
| 3 | Intent 3 | Pass | Preserves old multi-digit suffix behavior. |
| 4 | Intent 4 | Pass | Avoids silently broadening the implicit rule to underscores. |
| 5 | Intent 1 | Pass | Connects helper behavior to observable pretty output. |
| 6 | FVK honesty gate | Pass | The artifacts do not claim machine checking. |

No required behavior is marked fail or ambiguous.
