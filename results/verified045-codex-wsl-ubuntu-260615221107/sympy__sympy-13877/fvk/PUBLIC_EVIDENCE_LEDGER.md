# Public Evidence Ledger

See `SPEC.md` for the full table. Critical entries:

- E1/E2: the issue's `f(5) -> nan` and `f(6) -> TypeError` are symptoms, not
  behavior to preserve.
- E3: Bareiss is publicly described as valid for symbolic matrices.
- E4: input `nan` should return `nan` immediately.
- E5: pivot detection should expand candidates before accepting them.
- E6: determinant method names and public entry point should be preserved.

