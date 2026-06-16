# Spec Audit

Status: adequacy audit comparing `FORMAL_SPEC_ENGLISH.md` to
`INTENT_SPEC.md`.

| Claim | Intent match | Result |
|---|---|---|
| C1 | Matches I1, I2, I5, I6, D4 for nominal x default bounds. | pass |
| C2 | Matches I1, I2, I4, I5, I6, D4 for nominal y default bounds and inversion. | pass |
| C3 | Matches D2; public issue does not say `Plot.limit(...)` should be ignored. | pass |
| C4 | Matches I4 and D2 by preserving user limits while ensuring nominal y inversion. | pass |
| C5 | Matches D1 by keeping the policy scoped to nominal coordinates. | pass |
| C6 | Empty nominal axes are not specified by public intent. V1 avoids setting meaningless default limits but still disables grid. | ambiguous, non-blocking |
| C7 | Matches I6 and the implementation structure of `_finalize_figure`. | pass |

No formal claim is legacy-derived in a way that contradicts the public issue.
The only ambiguity is the empty-axis boundary, which is not needed to justify a
source edit because the issue does not state an expected empty-axis policy.
