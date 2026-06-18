# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "Incorrect parenthesizing of Subs" | The defect is in the way `Subs` renders grouping/parentheses. | Encoded in `SUBS-LOW-PRECEDENCE` and `ISSUE-EXAMPLE`. |
| E2 | `benchmark/PROBLEM.md` | Example input: `3*Subs(-x+y, (x,),(1,))` | The concrete reproduction uses an additive expression inside `Subs` as a multiplicative factor. | Encoded in `ISSUE-EXAMPLE`. |
| E3 | `benchmark/PROBLEM.md` | Reported output: `'3 \\left. - x + y \\right|_{\\substack{ x=1 }}'` | This is the legacy bug symptom, not expected behavior. | Marked SUSPECT; modeled only by `LEGACY-COUNTEREXAMPLE-DIAGNOSTIC`. |
| E4 | `benchmark/PROBLEM.md` | Desired output: `'3 \\left. \\left(- x + y\\right) \\right|_{\\substack{ x=1 }}'` | The additive expression must become `\left(- x + y\right)` inside the substitution bar. | Encoded in `SUBS-LOW-PRECEDENCE` and `ISSUE-EXAMPLE`. |
| E5 | `repo/sympy/printing/tests/test_latex.py` | Existing public expectation for `latex(Subs(x*y, (x, y), (1, 2)))` is `\left. x y \right|_{\substack{ x=1\\ y=2 }}`. | Non-additive multiplicative expressions should not gain extra parentheses. | Encoded in `PAREN-NONLOW-STRICT` and `SUBS-NONLOW-PRECEDENCE`. |
| E6 | `repo/sympy/printing/latex.py` | `parenthesize` wraps iff `prec_val < level`, or under non-strict mode iff `prec_val <= level`. | Implementation fact used to model V1 semantics; not independent intent. | Reflected in `mini-latex-printer.k`. |
| E7 | `repo/sympy/printing/precedence.py` | `Add` precedence is 40 and `Mul` precedence is 50. | Additive expressions are lower precedence than the multiplicative level used by V1. | Reflected in `prec(addExpr) => 40` and `prec(mulExpr) => 50`. |
