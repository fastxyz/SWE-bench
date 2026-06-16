# Iteration Guidance - sympy__sympy-17318

Status: constructed, not machine-checked.

## Applied V2 Source Change

The FVK audit found that V1's no-surd `split_surds` behavior was correct but
proved indirectly through `_split_gcd`'s empty-input neutral case. V2 adds an
explicit early return in `split_surds`:

`if not surds: return S.One, S.Zero, expr`

Trace: F2, PO2.

## Kept V1 Source Decisions

- Keep `_sqrt_match`'s strengthened positivity guard. Trace: F1, PO1.
- Keep `rad_rationalize`'s `if not a` early return. Trace: F3, PO4.
- Keep `split_surds` filtering to `Pow` terms with exponent `S.Half`. Trace:
  F3, F4, PO2, PO5.
- Keep `_split_gcd`'s empty neutral fallback as a defensive private-helper
  guard. Trace: F2, F5, PO3, PO6.

## Recommended Tests

Do not edit tests in this task. Future public tests should cover:

- `sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)` returns unchanged rather than
  raising.
- `rad_rationalize(1, 4 + I)` returns `(1, 4 + I)`.
- `rad_rationalize(1, 1 + cbrt(2))` returns unchanged without recursion.
- `rad_rationalize(1, sqrt(2) + I)` still returns `(sqrt(2) - I, 3)`.

## Machine-Check Follow-up

Run the commands listed in `fvk/PROOF.md` in an environment with K installed.
Until `kprove` returns `#Top`, treat the proof as constructed evidence and keep
the relevant tests.
