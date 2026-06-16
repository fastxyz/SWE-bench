# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "Result from clear_denoms() prints like zero poly but behaves wierdly (due to unstripped DMP)" | The defect is a non-canonical dense representation after `clear_denoms`. |
| E2 | `benchmark/PROBLEM.md` | `bad_poly.is_zero` -> `False`; `bad_poly.as_expr().is_zero` -> `True` | Representation-level zero and expression-level zero must agree for this result. |
| E3 | `benchmark/PROBLEM.md` | `bad_poly.rep` is `DMP([EX(0)], EX, None)` and should be `DMP([], EX, None)` | The specific univariate bad representation must become `[]`. |
| E4 | `benchmark/PROBLEM.md` | `bad_poly.terms_gcd()` raises `IndexError` while `Poly(0, x).terms_gcd()` works | Downstream dense methods require canonical zero; the fix belongs before those methods consume the representation. |
| E5 | `repo/sympy/polys/densetools.py` docstrings | "Clear denominators, i.e. transform K_0 to K_1." | The denominator-clearing algebraic behavior and conversion behavior must be preserved. |
| E6 | `repo/sympy/polys/densebasic.py` | `dup_strip` removes leading zeros and `_rec_strip` recursively strips dense polynomial lists. | Existing local canonicalization primitives should discharge the representation obligation. |
| E7 | `repo/sympy/polys/polyclasses.py` | `DMP.per()` returns `DMP(rep, dom, lev, ring)` without validating a list when `lev` is known. | The dense helper must return canonical `rep`; wrapper construction will not repair it. |

SUSPECT legacy evidence:

- The issue's displayed `bad_poly.is_zero == False` is the behavior being fixed,
  not an expected result.
- The issue's displayed `DMP([EX(0)], EX, None)` is the invalid representation,
  not a tolerated representation.
