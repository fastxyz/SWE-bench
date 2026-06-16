# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal item | Intent item | Verdict | Rationale |
| --- | --- | --- | --- |
| FE-1 | IS-2, E-5, E-7 | PASS | Right-aligned behavior is documented as the default and already publicly tested for manual iteration. |
| FE-2 | IS-1, IS-3, E-1, E-2, E-4, E-6 | PASS | The formal centered bounds are derived from the issue intent and `Variable.rolling_window`, not from legacy iterator behavior. |
| FE-3 | IS-3, E-6, E-8 | PASS | The offset identity is exactly the bridge between V1 arithmetic and the established centered padding convention, including even windows. |
| FE-4 | E-3 | PASS | The concrete claims match the issue's expected centered sequence and contradict the reported legacy sequence. |
| Iterator slices are clipped views, not padded arrays | IS-4, user guide manual-iteration example | PASS | Existing iterator behavior yields views; padded arrays would be a larger public behavior change not required by intent. |
| Labels and public API unchanged | IS-5 | PASS | The patch only changes slice bounds; method signature, yielded tuple shape, and multidimensional error behavior remain unchanged. |

No formal-English obligation is candidate-derived without public support.
