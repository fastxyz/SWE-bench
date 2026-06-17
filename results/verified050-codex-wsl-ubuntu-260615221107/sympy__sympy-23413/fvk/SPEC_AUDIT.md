# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent coverage | Verdict |
|---|---|---|
| HNF-TOTAL-CORRECT-SHAPE | Matches E1, E3, E5: compute HNF of `A`, preserve rank/module/rows. | Pass |
| HNF-ISSUE-INSTANCE | Matches E2 and E4: the issue transform must keep two columns and produce the expected row-style output. | Pass |
| HNF-RANK-DEFICIENT-TALL | Matches E5 and default HNF rank/module preservation. Conflicts with suspect public test E7, which encodes legacy behavior. | Pass with Finding F3 |
| OUTER-LOOP-CIRCULARITY | Matches E4 and E6: pivot discovery must continue above bottom `n` rows, while using the implementation's state variables. | Pass |
| INNER-LEFT-REDUCTION-CIRCULARITY | Matches E6 and default-domain unimodular-column-operation assumption. | Pass |
| RIGHT-REDUCTION-CIRCULARITY | Matches the HNF reduction condition in the implementation and docstring's HNF contract. | Pass |

No formal-English item is derived solely from V1 behavior. The V1 fallback is
explicitly rejected in Finding F1.
