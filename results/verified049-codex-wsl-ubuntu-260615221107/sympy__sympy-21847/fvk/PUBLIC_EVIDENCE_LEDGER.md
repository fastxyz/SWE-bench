# Public Evidence Ledger

Status: public evidence only; current implementation behavior is used only as implementation evidence.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`itermonomials` returns incorrect monomials when using optional `min_degrees` argument" | Audit integer `min_degrees` behavior as a correctness issue, not legacy behavior to preserve. | Encoded in I1-I4. |
| E2 | `benchmark/PROBLEM.md` | "should also return monomials such as `x1*x2**2, x2*x3**2`" | Mixed monomials with total degree `3` must pass the lower-bound filter. | Encoded in I3 and PO-4. |
| E3 | `benchmark/PROBLEM.md` quoting docs | "`min_degree <= total_degree(monom) <= max_degree`" | Integer mode is specified by total degree, not maximum per-variable exponent. | Encoded in I1 and all filter claims. |
| E4 | `benchmark/PROBLEM.md` | "monomials are also missing when `max_degrees` is increased above `min_degrees`" | The accepted set must include all total degrees in `[min_degree, max_degree]`, not just exactly equal bounds. | Encoded in I4. |
| E5 | Public hint in `benchmark/PROBLEM.md` | Suggested diff changes `max(powers.values())` to `sum(powers.values())` in both branches. | The root cause is lower-bound filtering by largest exponent; both commutative and non-commutative branches require the same total-degree filter. | Encoded in PO-4 and PO-5. |
| E6 | `repo/sympy/polys/monomials.py` docstring | "`min_degrees[i] <= degree_list(monom)[i] <= max_degrees[i]`" | List mode is per-variable and must remain unchanged by this fix. | Encoded in I7 and PO-7. |
| E7 | Public tests in `repo/sympy/polys/tests/test_monomials.py` | Default integer mode includes `{1}` for empty variables and degree-zero inputs. | Unit monomial has total degree `0`; it is valid when the lower bound is `0`. | Encoded in I5. |
| E8 | Total-degree docstring plus E7 | Empty variables have no positive-degree monomial. | For `variables == []` and integer `min_degree > 0`, yielding `1` violates the total-degree lower bound. | Finding F2; fixed in V2. |
| E9 | Public tests in `repo/sympy/polys/tests/test_monomials.py` | Negative integer `max_degrees` raises `ValueError`; list-mode bad shapes raise `ValueError`. | Preserve validation behavior. | Encoded in I6 and PO-1. |
| E10 | Source callsites from `rg "itermonomials\\(" repo/sympy` | Non-test callsites pass no `min_degrees`; signature unchanged. | No public compatibility change is required beyond preserving default behavior. | Encoded in I9 and PO-8. |
