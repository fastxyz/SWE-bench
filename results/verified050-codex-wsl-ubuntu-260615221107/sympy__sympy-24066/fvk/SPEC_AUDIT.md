# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent coverage | Result |
| --- | --- | --- |
| FS1 | Matches INTENT_SPEC 1 and 6. | Pass |
| FS2 | Matches INTENT_SPEC 2 and 5. | Pass |
| FS3 | Matches INTENT_SPEC 3. | Pass |
| FS4 | Matches INTENT_SPEC 4. | Pass |
| FS5 | Matches INTENT_SPEC 6. | Pass |
| FC1 | Matches INTENT_SPEC 5 and public compatibility evidence. | Pass |

No formal clause is derived solely from V1 behavior. The V2-only helper behavior
is justified by the audit finding that uncertainty must not be treated as proof
of equivalence or dimensionlessness.
