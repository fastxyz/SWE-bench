# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`sympy/simplify/sqrtdenest.py::_sqrt_match`

- Signature unchanged.
- Return shape unchanged: list of three elements for a match, empty list for no
  match.
- Public compatibility status: pass.

`sympy/simplify/radsimp.py::rad_rationalize`

- Signature unchanged.
- Return shape unchanged: `(num, den)`.
- Public compatibility status: pass.

`sympy/simplify/radsimp.py::split_surds`

- Signature unchanged.
- Return shape unchanged: `(g, a, b)`.
- New no-surd return `(S.One, S.Zero, expr)` is the neutral decomposition.
- Public compatibility status: pass.

`sympy/simplify/radsimp.py::_split_gcd`

- Private helper signature unchanged.
- Non-empty behavior unchanged.
- Empty input now returns a neutral split instead of raising.
- Source search found a non-test caller in `sympy/polys/numberfields.py`; that
  caller only passes a non-empty surd suffix, so compatibility is preserved.
