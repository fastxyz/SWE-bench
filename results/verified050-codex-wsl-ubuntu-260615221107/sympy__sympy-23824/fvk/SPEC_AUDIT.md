# SPEC_AUDIT.md

Status: constructed, not machine-checked.

| Formal English entry | Intent source | Adequacy result | Notes |
| --- | --- | --- | --- |
| RESTORE-ONE | E1, E2, E4 | Pass | It states the exact order-preservation property the issue identifies. |
| RESTORE-GENERAL | E1, E2, E7 | Pass | It generalizes the witness to every leading prefix and every result branch, matching "leading matrices ... should be unaffected." |
| RESTORE-WITNESS | E3 | Pass | It encodes the public reproduction's expected ordered result. |
| LEGACY-WITNESS | E1, E3, E4 | Pass as diagnostic claim | It is not a desired behavior claim; it demonstrates the pre-fix failure mechanism. |
| Frame condition | E4, E5 | Pass | The issue localizes the bug to restoration direction; the source diff leaves the contraction core unchanged. |

No formal claim depends on candidate behavior alone for the expected order. The
expected `[rho, sigma]` order comes from public intent, not from V1 output.
