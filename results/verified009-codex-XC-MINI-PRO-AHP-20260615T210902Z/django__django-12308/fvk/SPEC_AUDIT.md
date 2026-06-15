# Specification Adequacy Audit

Status: constructed, not machine-checked.

| Claim | Intent coverage | Verdict |
| --- | --- | --- |
| C-JSON-EXAMPLE | Matches intent items 1 and 2: the prompt's object example must not use Python repr. | Pass |
| C-JSON-NONINVALID | Matches intent items 1, 2, and 3 for the general non-null JSONField value family. | Pass |
| C-JSON-INVALID | Matches intent item 3: the prompt explicitly requires `prepare_value()` to account for `InvalidJSONInput`. | Pass |
| C-POSTGRES-SUBCLASS | Matches intent items 4 and 5: the public hint rejects brittle/coupled checks and asks for model JSONField instance behavior. | Pass |
| C-POSTGRES-INVALID | Matches intent items 3, 4, and 5: subclass handling must still preserve InvalidJSONInput through the same prepare path. | Pass |
| C-JSON-NONE | Matches intent item 6 and public admin null-display evidence E7. This is not derived from V1 alone. | Pass |
| C-NONJSON-FALLBACK | Matches intent item 7 as a frame condition: non-JSON field behavior is not part of the bug and remains unchanged. | Pass |

No formal claim is supported only by candidate behavior. The one potentially ambiguous branch, `None`, is grounded in public admin utility behavior rather than hidden tests or V1 convenience.
