# Spec Audit

Status: constructed for FVK audit; not machine-checked.

| Formal item | Intent item(s) | Adequacy result | Notes |
| --- | --- | --- | --- |
| SHORT-REP-PREFERENCE | Intent 2, 3; evidence E1, E4, E5, E6 | Pass | Encodes the public rule to try `str(value)` first when it fits. |
| LEGACY-FALLBACK | Intent 5; evidence E5, E8 | Pass | Preserves the issue author's explicit 20-character fallback boundary and the existing helper cap. |
| REPORTED-FLOAT | Intent 3; evidence E4 | Pass | Directly rejects the reported buggy token. |
| REPORTED-HIERARCH-CARD | Intent 1, 4; evidence E2, E3 | Pass | Connects helper output to the user-visible card image. |
| EXPONENT-NORMALIZATION | Intent 5; evidence E7 | Pass | Avoids proving a lower-case exponent output that existing verification treats as non-standard. |
| PARSED-VALUESTRING-FRAME | Intent 6; evidence E9 | Pass | Confirms V1 is scoped to newly formatted float values. |
| Public compatibility | Intent 7; evidence E10 | Pass | No changed public signatures or dispatch contracts. |

No formal-English claim is candidate-only or legacy-only. The only legacy
behavior preserved is the public/source-supported 20-character fallback path.
