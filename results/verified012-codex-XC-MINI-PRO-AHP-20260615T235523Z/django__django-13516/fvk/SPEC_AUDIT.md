# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal item | Intent item(s) | Verdict | Notes |
| --- | --- | --- | --- |
| `FLUSH-DELEGATES` | INT-1, INT-3 | Pass | It states direct delegation to the wrapped stream when `flush` exists, covering stdout and stderr because both are `OutputWrapper` instances. |
| `FLUSH-NO-METHOD-NOOP` | INT-5 | Pass | It preserves compatibility for stream-like objects without `flush`, which are not the positive target of the issue. |
| `PARTIAL-WRITE-THEN-FLUSH` | INT-2 | Pass | It captures the issue's required ordering: partial progress output becomes visible immediately after flush and before later success output. |
| Frame conditions | INT-4 | Pass | The candidate source change only adds `OutputWrapper.flush()` and does not alter write formatting, styling, or stream replacement call sites. |
| Nonnegative counters side condition | Default-domain assumption | Pass | The counters model output sizes and call counts; negative counts are outside the abstraction's measurement domain. |

No formal-English obligation is candidate-derived without public intent support. The only
candidate-derived detail, the `hasattr()` guard for streams without `flush`, is justified
as compatibility preservation rather than as a new user-visible requirement.
