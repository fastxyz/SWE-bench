# Intent Spec

Status: constructed from public/user-provided evidence only.

1. For the issue example `3*Subs(-x+y, (x,), (1,))`, LaTeX should render the
   substituted expression as a grouped body inside the substitution bar:
   `3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

2. The grouping obligation is about low-precedence substituted expressions,
   specifically additive expressions, being rendered as one body before a
   multiplicative coefficient.

3. The desired grouping is inside the `Subs` printer's body, not an outer pair
   of parentheses around the whole `Subs` factor.

4. Existing intended behavior for non-additive or multiplication-precedence
   substituted expressions should be preserved. The public in-repo latex test
   for `Subs(x*y, (x, y), (1, 2))` supports keeping `x y` unparenthesized.

5. No public API, printer method signature, or test file should change.
