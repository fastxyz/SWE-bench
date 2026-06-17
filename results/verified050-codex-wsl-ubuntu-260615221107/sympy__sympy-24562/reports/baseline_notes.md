# Baseline Notes

## Root cause

`Rational.__new__` normalized two-argument inputs by converting `p` first and immediately multiplying the raw `q` object by `p.q`. When `q` was a string, this used Python string repetition rather than rational arithmetic. For example, after converting `p='0.5'` to `1/2`, the old logic evaluated `'100' * 2`, producing `'100100'`, and the constructor returned `1/100100`.

The constructor already supports non-integer `p` and `q` values by converting each through `Rational(...)`. The bug was that the denominator contribution from `p` was applied before `q` had been converted to an integer numerator/denominator pair.

## Files changed

`repo/sympy/core/numbers.py`

Changed the two-argument normalization in `Rational.__new__` to keep the denominator contribution from `p` in a separate integer accumulator (`qden`). The code now converts `q` to a `Rational` before using its numerator and denominator, so inputs such as `Rational('0.5', '100')` are treated as `(1/2) / 100` instead of repeating the string denominator.

## Assumptions and alternatives

I assumed the intended behavior is for `Rational(p, q)` with individually valid rational-like inputs to match rational division of the two converted arguments. This matches the existing support for `Rational(1.0, 3)`, `Rational(1, 3.0)`, and the public hint comparing `Rational(p, q)` to `Rational('%s/%s' % (p, q))` for simple numeric values.

The issue text also says this "should probably raise an error." I considered rejecting string denominators in the two-argument form, but rejected that interpretation because the surrounding constructor already accepts non-integer arguments in either position, and the public hint points to correcting the arithmetic rather than removing accepted inputs.

I did not run tests or executable checks because the task explicitly forbids running tests or code in this session.
