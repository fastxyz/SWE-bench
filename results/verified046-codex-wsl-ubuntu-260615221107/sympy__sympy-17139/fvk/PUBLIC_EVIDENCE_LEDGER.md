# Public Evidence Ledger

| ID | Source | Quoted Evidence | Semantic Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | `simplify(cos(x)**I): Invalid comparison of complex I (fu.py)` | Avoid ordered comparison on complex exponent `I`; no crash on the reported path. |
| E2 | `_TR56` docstring | `Helper for TR5 and TR6 to replace f**2 with h(g**2)` | The helper's rewrite domain is even integer powers. |
| E3 | `_TR56` docstring | `max : controls size of exponent that can appear on f` | Exponents known greater than `max` remain unchanged. |
| E4 | `_TR56` docstring | `pow : controls whether the exponent must be a perfect power of 2` | `pow=True` narrows the rewrite domain to powers of two. |
| E5 | `_TR56` docstring | `f**6 will not be changed but f**8 will be changed` | `6` is a non-power-of-two example; `8` is a power-of-two example. |
| E6 | `_TR56` inline comment | `all even powers or only those expressible as powers of 2` | The local author intent distinguishes all even powers from powers of two. |
| E7 | `test_fu.py` public examples | `sin(x)**3` unchanged; `sin(x)**6` rewritten with `pow=False`; `sin(x)**6` unchanged with `pow=True`; `sin(x)**8` rewritten with `pow=True`. | Preserve documented examples across V2. |
| E8 | `perfect_power` implementation/docs | `ValueError is raised if n is not an integer or is not positive`; implementation calls `as_int(n)`. | Do not call `perfect_power` on symbolic integer exponents that are not concrete integers. |
