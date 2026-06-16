# Specification Adequacy Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent match | Evidence | Result |
| --- | --- | --- | --- |
| `SCORER-PARAMS`: scorer estimator receives path constructor parameters | Matches required behavior 1 and 3 | Ledger E2, E3, E4 | Pass |
| `MULTINOMIAL-SOFTMAX`: multinomial candidate selects softmax branch | Matches required behavior 2 | Ledger E1, E5, E6 | Pass |
| `SCORE-ALL-CANDIDATES`: each candidate score uses its own `C` and coefficient row | Matches required behavior 4 | Ledger E7 plus implementation shape of the existing loop | Pass |
| Frame: no public signature or return shape changes | Matches required behavior 5 | User task constraints and source diff | Pass |

## Adequacy conclusion

The formal claims cover the full intended behavior space for the reported
defect: all valid `multi_class` values in the scoring proxy and all candidates
in the `Cs` path. The claims intentionally do not cover optimizer convergence,
floating-point probability values, or log-loss arithmetic; those are outside
the bug mechanism and are recorded as proof capability limits in
`fvk/FINDINGS.md`.
