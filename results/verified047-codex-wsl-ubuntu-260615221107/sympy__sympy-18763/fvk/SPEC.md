# FVK Spec

Status: constructed, not machine-checked.

## Target

Audit the V1 fix for `sympy__sympy-18763`, limited to the public issue:
incorrect LaTeX parenthesizing of `Subs` when an additive substituted
expression appears as a factor in multiplication.

Relevant implementation units:

- `repo/sympy/printing/latex.py`: `LatexPrinter._print_Subs`.
- `repo/sympy/printing/latex.py`: `LatexPrinter.parenthesize`.
- `repo/sympy/printing/latex.py`: `LatexPrinter._print_Mul`, as the
  contributor that composes the factor string with coefficient `3`.
- `repo/sympy/printing/precedence.py`: `precedence_traditional` and
  `PRECEDENCE["Mul"]`.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E3: The prompt identifies `3 \left. - x + y \right|...` as buggy and
  gives the desired grouped output
  `3 \left. \left(- x + y\right) \right|...`.
- E4: Public in-repo coverage for `Subs(x*y, ...)` supports preserving
  multiplication-precedence bodies without new parentheses.
- E5-E6: Implementation evidence shows that multiplication prints each factor
  through `self._print(term)`, and the printer already has a precedence-aware
  helper that wraps only lower-precedence expressions under `strict=True`.

## Contract

For any `Subs(expr, old, new)` rendered by `LatexPrinter._print_Subs`:

1. If `precedence_traditional(expr) < PRECEDENCE["Mul"]`, the body of `expr`
   must be rendered as `\left(<latex(expr)>\right)` inside the substitution
   bar.
2. If `precedence_traditional(expr) >= PRECEDENCE["Mul"]`, the body of `expr`
   must be rendered without new parentheses.
3. The substitution suffix `\right|_{\substack{ old=new }}` is unchanged.
4. When `_print_Mul` composes a coefficient with the rendered `Subs` factor, the
   rendered factor must already be unambiguous. The issue case must therefore
   yield `3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

## Formal Core

The mini semantics is in `fvk/mini-python-printing.k`.

The K claims are in `fvk/latex-subs-spec.k`:

- issue-shaped additive product claim;
- general low-precedence body claim;
- frame claim for multiplication-or-higher precedence bodies.

This model is intentionally small. It preserves the property under verification:
whether the substituted body string is wrapped before multiplication prefixes
the rendered factor.

## V2 Decision

V1 satisfies this spec. No source edit is required beyond the existing V1 change:

```python
latex_expr = self.parenthesize(expr, PRECEDENCE["Mul"], strict=True)
```

The broader `Add`-only alternative was rejected because the existing helper
already expresses the intended precedence rule and preserves equality at
multiplication precedence.
