# FVK Findings - sympy__sympy-17318

Status: constructed, not machine-checked.

## F1 - Reported `sqrtdenest` IndexError path is closed

Input: `sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)`.

Pre-fix symptom from public issue: `IndexError` via `_sqrt_match(4 + I)` ->
`split_surds(4 + I)` -> `_split_gcd()` -> `a[0]`.

Expected: no exception; the non-denestable square-root part remains unchanged.

Candidate path after V2: `_sqrt_match(4 + I)` computes squared addends
`16` and `-1`; not all are positive, so the `split_surds` fast path is skipped.
Both addends have square-root depth `0`, so `_sqrt_match` returns `[]` and
`_sqrtdenest1` returns the original `sqrt(4 + I)` expression.

Classification: closed code bug. Covered by PO1.

## F2 - No-surd `split_surds` case needed an explicit source guard

Input: `split_surds(4 + I)`.

V1 candidate path: no `S.Half` powers are collected; `_split_gcd()` returned a
neutral empty split, causing `split_surds` to return `(1, 0, 4 + I)`.

Expected: no exception and no attempt to split non-existent square-root surds.

FVK audit result: V1 was behaviorally sufficient, but the proof obligation was
cleaner and better localized if `split_surds` itself returned early when no
square-root surds exist. V2 adds that explicit guard.

Classification: maintainability/source-localization improvement. Covered by
PO2 and PO3.

## F3 - `rad_rationalize` no-surd and higher-root cases are closed

Inputs:

- `rad_rationalize(1, 4 + I)`
- `rad_rationalize(1, 1 + cbrt(2))`

Pre-fix symptoms from public issue: `4 + I` raised `IndexError`; `1 + cbrt(2)`
could recurse indefinitely.

Expected: unchanged `(num, den)` because the function removes square roots, not
complex units or cube roots.

Candidate path after V2: `split_surds` finds no `S.Half` powers and returns
`(1, 0, den)`; `rad_rationalize` sees `a == 0` and returns `(num, den)`.

Classification: closed code bug. Covered by PO4.

## F4 - Valid square-root rationalization is preserved

Input: `rad_rationalize(1, sqrt(2) + I)`.

Public expected behavior: `(sqrt(2) - I, 3)`.

Candidate path after V2: `sqrt(2)` is still collected because it is a `Pow` with
exponent `S.Half`; `split_surds` returns the same square-root component as
before; `rad_rationalize` performs the conjugate step and the transformed
denominator is non-additive.

Classification: compatibility closed. Covered by PO5.

## F5 - Public caller compatibility is preserved

Inputs/callers: source search found `split_surds` and `rad_rationalize` callers
in `sqrtdenest.py`, `radsimp.py`, and `_split_gcd` use in
`polys/numberfields.py`.

Expected: no public signature or return-shape changes.

Candidate path after V2: all changed functions keep the same signatures and
tuple arities. `numberfields.py` only calls `_split_gcd` after proving a
non-empty surd suffix exists, so the neutral empty case is not a behavior change
for that caller.

Classification: compatibility closed. Covered by PO6.

## F6 - Proof capability boundary

The formal core models only the branch predicates and tuple return shapes needed
for the issue. It does not model all SymPy expression normalization,
auto-evaluation, ordering, or algebraic simplification semantics.

Classification: proof capability gap, not a code bug. The proof remains
constructed, not machine-checked.
