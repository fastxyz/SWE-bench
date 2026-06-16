# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "we should have (x*_2 - 5_x + 6, 3) and not 2 factors of multiplicity 3" | Combine same-multiplicity factors for the reported univariate `sqf_list()` expression. | Encoded in SPEC and PO-1. |
| E2 | `benchmark/PROBLEM.md` | Expanded-polynomial example returns `(x**2 - 1, 2)` as one factor of multiplicity `2`. | Expression-level `sqf_list()` should be consistent independent of whether input is expanded or factored. | Encoded in SPEC and PO-1. |
| E3 | `benchmark/PROBLEM.md` public hint | `Poly(..., x).sqf_list()` returns one `Poly(x**2 - 5*x + 6, x, ...)` for multiplicity `3`. | The expression helper should match the `Poly` convention for univariate input. | Encoded in PO-1 and PO-2. |
| E4 | `benchmark/PROBLEM.md` public hint | "It should scan the generic factor list and combine factors of same multiplicity before returning the list." | The repair should happen after generic factor-list construction, not by changing low-level `Poly.sqf_list()`. | Encoded in PO-2. |
| E5 | `benchmark/PROBLEM.md` public hint | "The squarefree methods are intended for univariate polynomials." | The verified domain is univariate square-free list output, with explicit single-generator input allowed. | Encoded in SPEC domain and PO-7. |
| E6 | `benchmark/PROBLEM.md` public hint | "Otherwise the result may be indeterminate" and "ValueError could be raised." | Multiple-generator behavior is an ambiguity, not a mandatory V1-blocking change. | Finding F-002. |
| E7 | `repo/sympy/polys/tests/test_polytools.py` | Existing public test expects `factor_list(x*(x + y))` and `sqf_list(x*(x + y))` to return two factors. | Public compatibility cautions against broad no-generator multivariate behavior changes without stronger intent. | Finding F-002 and PO-7. |
| E8 | `repo/sympy/polys/polytools.py` API names | `factor_list()` is an irreducible factor API; `sqf_list()` is square-free. | Grouping must be limited to `method == 'sqf'`. | PO-3. |
