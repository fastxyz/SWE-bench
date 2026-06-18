# Spec Audit

Status: pass for adequacy; constructed proof remains not machine-checked and
escalation-bounded for algebraic helper obligations.

| Formal obligation | Intent match | Audit result |
|---|---|---|
| Issue claim returns both `YMINUS1` and `XMINUS1`. | Matches issue statement that dropping `y - 1` is the bug. | Pass. |
| Legacy diagnostic returns only `XMINUS1`. | Matches reported symptom but is marked diagnostic/SUSPECT, not expected. | Pass. |
| No-content frame preserves primitive/norm path. | Matches regression-avoidance discipline and public intent not to alter unrelated factoring. | Pass. |
| Content-only frame returns lower-variable factors. | Entailed by "must not drop lower-variable factors." | Pass. |
| Coefficient claim combines `LC * CC`. | Entailed by complete factorization/reconstruction. | Pass. |
| General claim returns union of content and primitive factors. | Entailed by multivariate factorization intent. | Pass, subject to explicit helper obligations. |
| Factor order is unspecified. | Public evidence gives no order-sensitive requirement. | Pass. |
| API/return shape unchanged. | Required by callers and regression avoidance. | Pass. |

No formal-English obligation is weaker than the public intent. No obligation
over-preserves the legacy bug. The proof is not machine-checked, and the helper
algebra obligations remain explicit escalation boundaries rather than hidden
assumptions.
