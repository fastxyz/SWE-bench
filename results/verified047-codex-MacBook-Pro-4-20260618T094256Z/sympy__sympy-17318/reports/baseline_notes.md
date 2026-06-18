# Baseline Notes

## Root Cause

`sqrtdenest` eventually calls `_sqrt_match` on radicands such as `4 + I`.
The old `_sqrt_match` shortcut accepted any addends whose squares were
rational, so `I` was treated like a valid surd term because `I**2` is rational.
That shortcut then called `split_surds`, but `split_surds` only knew how to
split explicit square-root `Pow` terms. For an expression such as `4 + I`, it
collected no square-root surds and called `_split_gcd()` with no arguments,
raising `IndexError`.

The same unchecked path also affected direct callers of `split_surds` through
`rad_rationalize`. Expressions with no supported square-root surd, or with
non-square-root powers such as cube roots, could either reach `_split_gcd()`
with no useful input or recurse without making progress.

## Changed Files

`repo/sympy/simplify/sqrtdenest.py`

- Tightened `_sqrt_match` so the `split_surds` shortcut is used only when every
  addend square is both rational and positive. This excludes complex units such
  as `I` from the regular real-surd path and lets non-denestable expressions
  fall through to the existing unchanged-expression behavior.

`repo/sympy/simplify/radsimp.py`

- Updated `split_surds` to collect only explicit square-root terms
  (`Pow(..., S.Half)`) and to return `(1, 0, expr)` when no supported surd is
  present. This avoids calling `_split_gcd()` with an empty or irrelevant
  argument list.
- Updated `rad_rationalize` to stop and return the current numerator and
  denominator if `split_surds` found no square-root component to rationalize.
  This prevents non-progressing recursion for unsupported denominators.

## Assumptions and Rejected Alternatives

- I assumed the intended behavior for unsupported inputs is to leave them
  unchanged rather than raising. That matches the issue statement for
  `sqrtdenest` and preserves `rad_rationalize` as a best-effort helper.
- I rejected adding exception handling around `_split_gcd()` or callers because
  the failure is due to an invalid call shape, not an exceptional arithmetic
  condition.
- I rejected teaching `split_surds` to rationalize arbitrary complex terms such
  as `4 + I`; that would broaden the helper beyond its documented square-root
  surd contract and is not needed for the reported crash.
- I did not add or modify tests, and did not run tests or code, because the task
  explicitly forbids both.
