# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| 1 | Intent 1, 2, 3 | Pass | Captures NFKD followed by combining-mark removal. |
| 2 | Intent 1, 3 | Pass | Makes the filter exact and order-preserving. |
| 3 | Intent 4 | Pass | Encodes precomposed n-with-tilde. |
| 4 | Intent 3, 4 | Pass | Encodes already-NFKD decomposed input. |
| 5 | Intent 3, 4 | Pass | Encodes removal of the combining tilde. |
| 6 | Intent 4 | Pass | Matches the public expected result. |
| 7 | Intent 1 and user constraints | Pass | Domain and non-goals are explicit rather than implementation-derived. |

No formal claim is legacy-derived from the old early return. No required behavior is marked ambiguous or failed.

