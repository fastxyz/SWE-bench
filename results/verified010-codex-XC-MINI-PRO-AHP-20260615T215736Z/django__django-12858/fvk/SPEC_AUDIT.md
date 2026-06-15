# SPEC_AUDIT.md

Status: constructed, not machine-checked.

| Formal English entry | Intent entry | Verdict | Notes |
| --- | --- | --- | --- |
| `REPORTED-CASE` accepts final `isnull` after resolved FK path. | I-001, I-002 | Pass | Directly matches the public issue. |
| `FINAL-LOOKUP-VALID` accepts final registered lookup. | I-001 | Pass | Generalizes the issue title from `isnull` to registered final lookups. |
| `TRANSFORM-STILL-VALID` preserves registered transform acceptance. | I-004 | Pass | Existing behavior not challenged by the issue. |
| `NONFINAL-LOOKUP-INVALID` rejects lookup-only middle segment. | I-005 | Pass | Prevents over-broad acceptance and preserves invalid-path checks. |
| Leading `-` handling unchanged. | I-003 | Pass | The modified code is after the existing sign-stripping generator. |
| Check framework API unchanged. | I-006 | Pass | No signature, return type, or check ID changed. |

No formal English entry fails or remains ambiguous.
