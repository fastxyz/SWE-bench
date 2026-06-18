# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

### `sympy.simplify.sqrtdenest._sqrt_match`

- Signature changed: no.
- Return shape changed: no. The function already returned either a list-like
  match result or `[]`; V1 continues that protocol.
- Public/internal callsites found under `repo/sympy`: `_sqrtdenest1`,
  `_sqrt_symbolic_denest`, `_denester`, and docstring examples in
  `sqrtdenest.py`.
- Compatibility status: pass. V1 narrows only the shortcut that calls
  `split_surds`; no caller protocol changes.

### `sympy.simplify.radsimp.split_surds`

- Signature changed: no.
- Return shape changed: no. The function still returns `(g, a, b)`.
- Public/internal callsites found under `repo/sympy`: `rad_rationalize` and
  `_sqrtdenest_rec`.
- Compatibility status: pass. V1 adds a no-surd 3-tuple for unsupported inputs
  and leaves supported square-root inputs on the existing path.

### `sympy.simplify.radsimp.rad_rationalize`

- Signature changed: no.
- Return shape changed: no. The function still returns `(num, den)`.
- Public/internal callsites found under `repo/sympy`: `radsimp` internals,
  `_sqrtdenest_rec`, `sqrt_biquadratic_denest`, and its own docstring example.
- Compatibility status: pass. V1 stops unsupported no-surd denominators without
  changing supported denominator handling.

## Overrides and Dispatch

No subclass overrides or virtual dispatch points are involved. The edited
functions are module-level helpers.

## Producer/Consumer Protocols

- `split_surds -> rad_rationalize`: compatible, because `(1, 0, expr)` lets
  `rad_rationalize` identify no square-root progress with `not a`.
- `split_surds -> _sqrtdenest_rec`: compatible for supported square-root inputs;
  unsupported no-surd inputs now have a safe tuple shape rather than an internal
  `_split_gcd` exception.
- `_sqrt_match -> _sqrtdenest1/_denester`: compatible, because `[]` was already
  the no-match sentinel.

No compatibility finding forces a source edit.
