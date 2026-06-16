# Intent Spec

Status: intent-only, derived from public issue text and local public docs/tests. Current implementation behavior is treated only as observed behavior to check.

I-001: `polylog(2, Rational(1, 2))` should evaluate to `pi**2/12 - log(2)**2/2` without needing a user workaround.

I-002: `polylog(2, Rational(1, 2)).expand(func=True)` should not remain unevaluated; it should expose the same closed form as I-001.

I-003: `expand_func(polylog(1, z))` should return `-log(1 - z)` and should not contain `exp_polar(-I*pi)`.

I-004: Existing automatic values for `z = 0`, `z = 1`, and `z = -1` should be preserved.

I-005: Existing documented symbolic identities for order `1`, order `0`, and negative integer orders remain opt-in `expand_func` identities unless a concrete special value is independently required on construction.

I-006: `lerchphi` expansion paths that delegate to `polylog` should continue to produce expression values after `polylog(2, 1/2)` begins evaluating automatically.
