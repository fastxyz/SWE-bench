# Spec Audit

Status: pass. The formalized obligations match the intent-only spec.

| Formal item | Intent item | Audit result | Notes |
| --- | --- | --- | --- |
| PLAIN-EMPTY-SUFFIX | Required behavior 2 | Pass | Empty suffix omission follows from issue discussion of empty strings causing whitespace. |
| PLAIN-NONEMPTY-SUFFIX | Required behavior 1 | Pass | Directly matches the expected `("name" DESC)` shape. |
| INDEX-EMPTY-SUFFIX | Required behavior 3 | Pass | Directly matches expected `("name" text_pattern_ops)`. |
| INDEX-NONEMPTY-SUFFIX | Required behavior 4 | Pass | Matches the issue's statement that descending opclass use should look correct. |
| MULTI-COLUMN-PRESERVATION | Required behavior 5 | Pass | The issue does not request delimiter changes; source preservation is appropriate. |
| COMPATIBILITY-PRESERVATION | Required behavior 6 | Pass | No signatures or dispatch shapes changed. |

## Ambiguities

Pre-spaced or whitespace-only suffix fragments are not specified by public intent. They are recorded as F-4 and are not used to justify a source change.
