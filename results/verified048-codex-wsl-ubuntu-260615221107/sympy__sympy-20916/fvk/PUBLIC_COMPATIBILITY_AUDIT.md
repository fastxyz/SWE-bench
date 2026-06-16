# Public Compatibility Audit

Changed public symbol: none.

Changed internal helper: `_name_with_digits_p` in
`sympy.printing.conventions`.

Public API shape:

- `split_super_sub(text)` still accepts one argument.
- `split_super_sub(text)` still returns `(name, supers, subs)`.
- Callers in unicode pretty printing and LaTeX still call the same helper.
- No subclass, override, virtual dispatch, storage format, or return-shape
  change is introduced.

Compatibility verdict: pass.
