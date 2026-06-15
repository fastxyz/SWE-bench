# Spec Audit

Constructed, not machine-checked.

| Formal obligation | Intent match | Reason |
| --- | --- | --- |
| Omitted `batch_size` uses compatible cap. | Pass | Matches the issue's suggested fallback branch and preserves preexisting no-user-batch behavior. |
| Explicit positive `batch_size <= cap` is preserved. | Pass | The issue asks to prevent overriding the compatible maximum, not to force larger batches. Keeping a smaller user value is the behavior implied by "minimum of two." |
| Explicit positive `batch_size > cap` clamps to cap. | Pass | This is the directly reported bug and matches the issue's suggested logic. |
| Every emitted slice length is `<= cap`. | Pass | This is the observable safety property needed for backend parameter limits. |
| Emitted slice lengths sum to the object count. | Pass | This frame/completeness property ensures clamping does not drop or duplicate objects during batching. |
| Positive explicit batch-size precondition. | Pass | Existing `bulk_create()` validation asserts positive explicit sizes; the issue does not ask to change invalid-value handling. |
| Backend cap `C >= 1` after lower bound. | Pass with assumption | Existing Django code already lower-bounds `ops.bulk_batch_size()` by one in `_batched_insert()`. This audit preserves that behavior and scopes the proof to supported insertable batches. |
| No API, branch, or return-shape change. | Pass | The source edit changes only a local effective-batch calculation and leaves signatures and branch structure intact. |

No formal-English obligation is weaker than the public issue intent. No obligation preserves the legacy buggy behavior where `U > C` still emits batches of size `U`.
