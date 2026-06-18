# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "we should have (x*_2 - 5_x + 6, 3) and not 2 factors of multiplicity 3" | Same-multiplicity factors in the reported univariate expression must be combined into one product. | Encoded in `sqf-combine-spec.k` claim 1. |
| E2 | `benchmark/PROBLEM.md` | `Poly(..., x).sqf_list()` returns `Poly(x**2 - 5*x + 6, x)` at multiplicity `3`. | Expression-level `sqf_list(..., x)` should match the Poly method's grouping shape for the same univariate input. | Encoded in claims 1 and 5. |
| E3 | `benchmark/PROBLEM.md` | "It should scan the generic factor list and combine factors of same multiplicity before returning the list." | The repair belongs after generic factor-list construction and before final return conversion. | Encoded in `normalizeFactors(sqf, ...)` claim. |
| E4 | `benchmark/PROBLEM.md` | "The square free algorithm should pull out all factors of _same_ degree and present them as one product of given multiplicity" | Grouping is a family property over all equal multiplicities, not just exponent `3`. | Encoded in exponent-1 and exponent-5 claims. |
| E5 | `benchmark/PROBLEM.md` | "The squarefree methods are intended for univariate polynomials" and multiple-generator behavior is discussed as ambiguous. | The formal in-domain obligation is univariate/same-generator grouping; multiple-generator behavior is not used to force a broad rewrite. | Encoded as a domain/frame condition. |
| E6 | `repo/sympy/polys/tests/test_polytools.py` | `sqf_list(x*(x + y)) == (1, [(x, 1), (x + y, 1)])` | Preserve current mixed-generator symbolic-product behavior unless a public-intent finding forces a change. | Encoded in the mixed-generator frame claim. |
| E7 | `repo/sympy/polys/polytools.py` | V1 calls `_combine_factors` only when `method == 'sqf'`. | `factor_list()` must not be affected by the new helper. | Encoded in `normalizeFactors(factor, ...)` claim. |
| E8 | `reports/baseline_notes.md` | V1 intentionally did not replace the whole public function with `Poly(...).sqf_list()`. | Audit V1's actual strategy: minimal post-processing plus frame preservation. | Reflected in `SPEC.md` and `FINDINGS.md`. |
