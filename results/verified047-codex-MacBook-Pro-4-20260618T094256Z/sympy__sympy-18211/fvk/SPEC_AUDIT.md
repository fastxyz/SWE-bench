# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent item | Audit |
|---|---|---|
| `REL-EVAL-EXACT` preserves exact solver result `S`. | Intent obligation 1 and public tests for solved relationals. | PASS. This is directly required by the regression frame. |
| `REL-EVAL-UNSOLVED` returns `ConditionSet(symbol, original_relational, Reals)`. | Intent obligation 2 and problem expected output. | PASS. The formal fallback matches the public expected result shape. |
| `BOOL-AS-SET-NONPERIODIC-EXACT` returns exact `S`. | Intent obligations 3 and 4. | PASS. Public `as_set()` remains exact when the solver succeeds. |
| `BOOL-AS-SET-NONPERIODIC-UNSOLVED` returns real `ConditionSet`. | Intent obligations 2 and 3. | PASS. This is the reported public observable. |
| Other exception classes are not converted. | Intent frame condition: only solver `NotImplementedError` is implicated. | PASS. No public evidence requires catching broader failures. |
| Multivariate and non-trivial periodic paths remain unchanged. | Intent obligation 5. | PASS. The issue is univariate and no finding implicates those paths. |

## Adequacy Result

The formal English matches the intent spec for the audited behavior. No formal
claim is legacy-derived without public support. No adequacy failure or ambiguity
blocks the "V1 stands" decision.
