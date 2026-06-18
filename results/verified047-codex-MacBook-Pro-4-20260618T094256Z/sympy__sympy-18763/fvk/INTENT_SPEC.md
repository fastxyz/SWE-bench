# Intent Spec

Status: constructed, not machine-checked.

## Scope

The audited behavior is LaTeX rendering of `Subs` in
`repo/sympy/printing/latex.py`, specifically the expression printed before the
substitution evaluation bar and its interaction with multiplication.

## Intent-derived obligations

1. For the issue input `3*Subs(-x+y, (x,), (1,))`, the additive expression
   governed by the substitution bar must be parenthesized inside the `Subs`
   rendering: the observable shape is
   `3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

2. The reported legacy shape
   `3 \left. - x + y \right|_{\substack{ x=1 }}` is the bug symptom and must
   not be preserved as expected behavior.

3. The substitution assignment suffix remains the same while the expression
   before the bar is corrected.

4. Non-additive expressions that already print unambiguously, represented by
   the public in-repo expectation for `Subs(x*y, (x, y), (1, 2))`, must not gain
   extra parentheses.

## Default-domain assumptions

1. The proof models only the printer fragment needed for the issue: additive
   expressions, multiplicative expressions, atomic expressions, and derivative-
   precedence expressions.

2. The intended grouping rule for this fragment is the standard LaTeX printer
   precedence rule already used locally: an expression with precedence lower
   than `Mul` is wrapped before it is rendered as a multiplicative operand-like
   expression; expressions at `Mul` precedence or tighter are left as-is under
   `strict=True`.

3. The audit is partial-correctness only for this rendering function fragment.
   It does not prove termination, full SymPy expression coverage, or correctness
   of unrelated LaTeX printer methods.
