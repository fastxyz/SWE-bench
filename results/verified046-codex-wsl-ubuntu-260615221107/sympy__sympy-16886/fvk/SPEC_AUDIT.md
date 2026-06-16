# Spec Adequacy Audit

| Formal claim | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| `(MORSE-TABLE-ONE)` | Intent 1 | Pass | Directly encodes the problem statement's corrected mapping. |
| `(MORSE-INVERSE-ONE)` | Intent 4 | Pass | Follows from the public implementation fact that `char_morse` is derived. |
| `(ENCODE-ONE)` | Intent 2 | Pass | Covers the reported public symptom in the encode direction. |
| `(DECODE-ONE)` | Intent 3 | Pass | Covers the source-table decode direction implied by the corrected mapping. |
| `(DIGIT-FAMILY)` | Intent 5 | Pass | Applies FVK's family/table completeness rule to the digit family. |
| API frame | Intent 6 | Pass | No public signature or call-shape change. |

No formal claim is candidate-derived without public intent support, and no claim
preserves the pre-V1 legacy mapping as expected behavior.

