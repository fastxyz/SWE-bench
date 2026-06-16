# Spec Audit

Status: adequacy comparison between `INTENT_SPEC.md` and `FORMAL_SPEC_ENGLISH.md`.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| `CLAIM-PREPARE-INVALID` | Intent 3 | Pass | Preserves invalid redisplay; not in conflict with the Unicode display issue. |
| `CLAIM-PREPARE-UNICODE-CHINA` | Intent 1 and 2 | Pass | Concrete discriminator proves the issue example reaches readable Unicode display. |
| `CLAIM-PREPARE-GENERAL` | Intent 1, 2, and 4 | Pass | Generalizes the normal branch to all non-invalid JSON values while preserving the encoder. |
| Database serialization frame | Intent 5 | Pass | Matches the public issue's display-only scope. |
| Widget rendering frame | Intent 6 | Pass | Confirms the fix does not bypass template escaping. |
| Bound valid JSON redisplay composition | Intent 1 and 2 | Pass | Covers the redisplay path where valid JSON is decoded before display. |

No item fails or remains ambiguous. The legacy escaped Unicode output is explicitly treated as the reported bug, not as a compatibility requirement.
