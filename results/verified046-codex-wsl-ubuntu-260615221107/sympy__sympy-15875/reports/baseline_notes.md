# Baseline Notes

## Root cause

`Add._eval_is_zero` tracked the presence of definitely imaginary terms with a
single boolean. When the real part of the `Add` was known to be zero and there
were no possibly-imaginary-or-zero terms, the handler returned `False` as soon
as any imaginary term was present.

That conclusion is valid for a single nonzero imaginary addend, such as
`0 + I`, but it is not valid for multiple imaginary addends. Those addends can
cancel each other, as in `-2*I + (1 + I)**2`. The old logic therefore reported
that some zero-valued complex sums were definitely nonzero.

## Files changed

`repo/sympy/core/add.py`

- Changed `_eval_is_zero` to collect definitely imaginary addends as real
  coefficients by multiplying them by `I`, instead of collapsing them to a
  boolean flag.
- When the real part is zero and all imaginary addends are definitely
  imaginary, the handler now checks whether the collected imaginary
  coefficients are known to sum to zero or nonzero.
- If the coefficient sum is undecidable, the handler only returns `False` for
  same-sign coefficient groups, where cancellation is impossible. Otherwise it
  leaves the result unknown (`None`), which avoids the incorrect `False` from
  the reported issue.

## Assumptions and rejected alternatives

- I assumed the assumptions handler should stay conservative and quick; it
  should not expand or simplify complex powers just to prove this example is
  zero.
- I relied on SymPy's documented assumption behavior that `is_imaginary=True`
  excludes zero. This preserves the existing ability to conclude that a single
  imaginary addend with a zero real part is nonzero.
- I considered simply removing the `return False` for imaginary terms, but that
  would lose correct results for obvious cases like `0 + I`.
- I considered returning `None` for every multi-term imaginary group, but that
  would unnecessarily lose safe conclusions for same-sign groups such as
  positive imaginary coefficients that cannot cancel.
