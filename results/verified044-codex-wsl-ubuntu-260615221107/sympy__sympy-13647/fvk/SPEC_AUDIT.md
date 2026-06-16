# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent evidence | Audit result | Notes |
|---|---|---|---|
| C-SHAPE | E5, E6 | Pass | Insertion adds the inserted column count and preserves row count. |
| C-LEFT | E5 | Pass | Inserting columns does not change entries before the insertion point. |
| C-INSERT | E2, E5 | Pass | Inserted columns occupy the target interval in their original order. |
| C-RIGHT | E3, E4, E5, E7 | Pass | This is the issue's failed behavior and the public hint's target. |
| C-PUBLIC-GUARDS | E6, E8 | Pass | V1 did not alter guards; they supply the helper preconditions. |
| C-NULL | E9 | Pass | V1 does not alter the documented source-comment branch for null matrices. |
| Frame conditions | E5, E6 | Pass | V1 keeps API and dispatch shape unchanged. |

No claim is derived solely from the V1 implementation. The right-frame mapping
matches prompt intent and the public hint rather than preserving the legacy
pre-fix output.
