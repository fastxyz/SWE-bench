# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt issue | "`Eq(n*cos(n) - 3*sin(n), 0).as_set()` ... `NotImplementedError`" | The public observable is `as_set()` on a univariate `Equality`; leaking `NotImplementedError` is the bug. | Encoded in BOOL-AS-SET-NONPERIODIC-UNSOLVED. |
| E2 | prompt issue | "probably a `ConditionSet` should be returned" | Solver incompleteness must be represented as an unevaluated set, not an exception. | Encoded in REL-EVAL-UNSOLVED. |
| E3 | prompt issue | "ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)" | The fallback set must preserve the original relational condition, its symbol, and the real base set. | Encoded in REL-EVAL-UNSOLVED and BOOL-AS-SET-NONPERIODIC-UNSOLVED. |
| E4 | prompt hint | The public hint catches `NotImplementedError` in `Relational._eval_as_set()` and returns `ConditionSet(x, self, S.Reals)`. | The named repair point is the relational conversion boundary, not the solver API. | V1 matches this shape. |
| E5 | source docstring | `Boolean.as_set()` says it "Rewrites Boolean expression in terms of real sets." | The default base domain for the fallback is real. | Encoded as the `reals` base in `conditionSet`. |
| E6 | source docstring | `solve_univariate_inequality` documents `NotImplementedError` when solution cannot be determined due to solver limitations. | Catching that exception at `as_set()` is handling an expected incompleteness signal. | Encoded in REL-EVAL-UNSOLVED. |
| E7 | public in-repo tests | Existing tests assert exact sets for `(x > 0).as_set()`, `Eq(x, 0).as_set()`, `Ne(x, 0).as_set()`, and `(x**2 >= 4).as_set()`. | Exact solver results must remain unchanged. | Encoded in REL-EVAL-EXACT and BOOL-AS-SET-NONPERIODIC-EXACT. |
| E8 | implementation | `Boolean.as_set()` rejects multivariate expressions and non-trivial periodic relational sets separately. | V1 should not refactor those paths without a finding. | Recorded as a frame condition; no edit applied. |
