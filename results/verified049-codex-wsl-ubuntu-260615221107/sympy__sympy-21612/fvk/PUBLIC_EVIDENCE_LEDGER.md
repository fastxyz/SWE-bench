# Public Evidence Ledger

Status: public evidence only; no hidden tests, internet, prior results, or execution used.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | Problematic expression `\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}` is parsed/displayed as `((a**3 + b)/c)/1/(c**2)`. | Nested denominator fractions must be grouped when printed. | Encoded in `SPEC.md`, `PROOF_OBLIGATIONS.md`, and `str-printer-spec.k`. |
| E2 | `benchmark/PROBLEM.md` | Expected is `((a**3 + b)/c)/(1/(c**2))`. | The denominator `1/(c**2)` is a single denominator expression of the outer quotient. | Encoded as a `Pow`-base denominator obligation. |
| E3 | `benchmark/PROBLEM.md` | Simplified failure: `parse_latex("\frac{a}{\frac{1}{b}}")` prints `a/1/b`; expected grouping is implied by the issue. | The minimal nested reciprocal denominator must print as `a/(1/b)`. | Primary proof claim. |
| E4 | `benchmark/PROBLEM.md` public hint | The expression args are reported as `(a, 1/(1/b))`. | Parser output is already structurally grouped; printer output must not flatten that grouping. | Supports keeping parser unchanged. |
| E5 | `benchmark/PROBLEM.md` public hint | Suggested source change extends `isinstance(item.base, Mul)` to include `Pow`. | `Pow` denominator bases need the same explicit grouping as `Mul` bases. | V1 implements this. |
| E6 | `repo/sympy/parsing/latex/_parse_latex_antlr.py` | Fraction conversion builds `inverse_denom = sympy.Pow(expr_bot, -1, evaluate=False)` and returns `sympy.Mul(expr_top, inverse_denom, evaluate=False)`. | `_print_Mul` receives the denominator expression as the base of a reciprocal `Pow`. | Used as implementation evidence for the formal model. |
| E7 | `repo/sympy/printing/tests/test_str.py` | Existing issue 14160 assertion expects an unevaluated `Mul(y, y)` denominator base to print as `-2*x/(y*y)`. | `Mul`-base parenthesizing must be preserved. | Frame obligation; V1 preserves it. |
| E8 | `repo/sympy/printing/tests/test_str.py` | Existing assertions expect simple quotients such as `x/y` and `x/(y*z)`. | Simple denominators remain compact, and multiple denominator factors remain grouped. | Frame obligation; V1 only changes `Pow` base classification for exp `-1`. |
