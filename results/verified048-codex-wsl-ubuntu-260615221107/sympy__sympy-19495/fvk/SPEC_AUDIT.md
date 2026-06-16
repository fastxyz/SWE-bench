# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent Match | Audit |
| --- | --- | --- |
| C1 | Pass | Entailed by I1 and E4. The condition is independent of the dummy, so once the external guard is true, the set is exactly the substituted base. |
| C2 | Pass | Entailed by I2, I3, E2, and E3. It captures the reported output form and localizes the issue away from `ImageSet.subs`. |
| C3 | Pass | Entailed by I4 and E5. This prevents the V1 audit from over-correcting the assumption-sensitive branch. |
| C4 | Pass | Entailed by I5 and E6 as a frame condition for the unchanged non-true branch. |
| C5 | Pass | Entailed by I5 and the source diff: no signature or dispatch shape changed. |

No claim is legacy-only in conflict with the public issue. The only preserved
legacy behavior, C3, is supported by public in-repo tests and applies to a
different dummy-dependent branch than the reported external-guard bug.

