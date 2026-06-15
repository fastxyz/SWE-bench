# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent entries | Verdict | Notes |
| --- | --- | --- | --- |
| C-001 missing cutoff returns `rows(NUM)` | I-001, E-001, E-002 | pass | This is the core issue behavior. The claim is intentionally weaker than "must cull anyway" because public intent requires no TypeError, and concurrent row removal can make the table already acceptable. |
| C-002 frequency one returns `rows(0)` | I-003, E-003 | pass | This follows from the documented culling ratio and closes the deterministic offset-past-end case. |
| C-003 present cutoff preserves ratio deletion | I-004, E-005 | pass | This keeps the existing backend-specific cutoff strategy when the cutoff row exists. |
| C-004 zero frequency returns `rows(0)` | I-002, E-004 | pass | This preserves documented behavior. |
| C-005 no cull below max returns `rows(NUM)` | I-004 by frame condition | pass | The issue does not request changing below-limit behavior. |
| Domain excludes negative cull frequencies | A-001 | ambiguous but acceptable | Public docs describe an integer fraction and only give special meaning to zero. Negative values are not part of this issue or documented behavior. |

No claim depends on a public test or pre-fix display that encodes the reported TypeError as intended behavior.
