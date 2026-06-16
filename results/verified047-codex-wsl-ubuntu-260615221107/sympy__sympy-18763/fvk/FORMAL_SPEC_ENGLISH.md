# Formal Spec English

The formal claims are in `fvk/latex-subs-spec.k`. They are constructed, not
machine-checked.

1. `ISSUE-ADD-SUBS` shape: Rendering the issue expression as a product of
   coefficient `3` and `Subs(-x + y, x, 1)` must produce exactly
   `3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

2. Low-precedence body claim: For any substituted expression whose precedence
   is lower than multiplication (`PREC < 50`), `_print_Subs` must wrap the body
   string as `\left(<body>\right)` before appending the substitution bar.

3. Frame claim for multiplication-or-tighter bodies: For any substituted
   expression whose precedence is at least multiplication (`PREC >= 50`),
   `_print_Subs` must leave the body string unwrapped before appending the
   substitution bar.

4. Composition claim: Multiplication prefixes the rendered `Subs` factor with
   the coefficient and separator. It does not add an outer wrapper around the
   whole substitution expression for the issue case.
