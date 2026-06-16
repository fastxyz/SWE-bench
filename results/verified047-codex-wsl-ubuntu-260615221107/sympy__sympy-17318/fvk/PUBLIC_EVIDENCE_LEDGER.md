# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | prompt | "If an expression cannot be denested it should be returned unchanged." | Unsupported `sqrtdenest` inputs preserve expression and do not raise. |
| I2 | public hint | "`sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)` raises the same error" | Cover flat `4 + I`, not only the auto-evaluating original input. |
| I3 | public hint | "`4+I` ... leads to an empty `surds` list" | Empty surd lists must be handled at the source. |
| I4 | public hint | "`rad_rationalize(1,4+I)` ... shouldn't fail"; `1+cbrt(2)` recurses | No-surd and higher-root denominators stop unchanged. |
| I5 | public hint | "`rad_rationalize(1,sqrt(2)+I)` returns `(sqrt(2) - I, 3)`" | Valid square-root rationalization is preserved. |
| I6 | public hint | "Please do not add bare except statements." | Use branch guards, not exception swallowing. |
