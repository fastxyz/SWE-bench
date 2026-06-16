# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`Mod(3*i, 2)` should reduce to `Mod(i, 2)`" | default-path simplification for integer coefficient case |
| E2 | `repo/sympy/core/mod.py` docstring | "remainder always has the same sign as the divisor" | Python modulo semantics |
| E3 | public hint | "`Mod(var('e',even=True)/2,2)==0` ... should remain unevaluated" | denominator/rational coefficient guard |
| E4 | public hint | "An even number divided by 2 may or may not be even" | do not infer parity of `e/2` from parity of `e` |
| E5 | public hint | "`(x - 3.3) % 1`" corner case | preserve float/additive behavior |
| E6 | public tests | symbolic divisor examples around `test_arit.py` lines 1610-1623 | preserve symbolic-divisor handling |
