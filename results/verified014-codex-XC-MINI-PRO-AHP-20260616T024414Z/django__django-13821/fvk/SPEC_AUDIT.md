# Spec Audit

Status: constructed for FVK, not machine-checked.

| Formal English item | Intent item | Verdict | Reason |
| --- | --- | --- | --- |
| Reject all versions below `(3, 9, 0)`. | Intent 1, 2; evidence E1. | Pass | This is the direct meaning of dropping support for SQLite `< 3.9.0`. |
| Accept `(3, 9, 0)` and later versions. | Intent 3; evidence E1, E2. | Pass | The issue drops only versions below 3.9.0 and explicitly preserves 3.11.0. |
| Raise an `ImproperlyConfigured` message naming SQLite 3.9.0. | Intent 2; implementation evidence E4. | Pass | Existing backend behavior enforces support floors by import-time `ImproperlyConfigured`; V2 updates the threshold and message consistently. |
| Preserve runtime JSON1 probing. | Intent 5; evidence E3. | Pass | The issue says JSON1 is compile-time optional, so a numeric version check alone is insufficient. |
| Update current docs to 3.9.0. | Intent 4; evidence E5, E6. | Pass | V2 updates the active current docs and leaves historical release notes unchanged. |

No required behavior is marked fail or ambiguous.
