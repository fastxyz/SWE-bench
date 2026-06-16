# Spec Adequacy Audit

| Formal English claim | Intent coverage | Result |
| --- | --- | --- |
| `STANDALONE-SEP-KEYS` | Matches INT-1 and INT-3. | Pass |
| `NORMAL-COMPOUNDS` | Matches INT-4 and INT-5 frame obligations. | Pass |
| `ADJACENT-SEP-AS-KEY` | Matches INT-2 and the generalized family from INT-3. | Pass |
| `GENERAL-POSITIONAL-TOKENIZATION` | Matches INT-2 over the intent-derived `KeyboardSeq` domain. | Pass |
| `RUN-NODE-SHAPE` | Matches INT-1, INT-2, and the existing HTML transform's observable responsibility. | Pass |
| Compatibility claim | Matches INT-6. | Pass |

No formal claim relies on the issue's pre-fix broken HTML as an oracle. That
legacy output remains SUSPECT because the issue identifies it as the bug.

The malformed adjacent-separator shape in F-4 is not part of the formal domain.
This is marked as an ambiguity, not as a pass.
