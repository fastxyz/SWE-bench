# Baseline Notes

## Root cause

The internal `evalf` fallback in `sympy/core/evalf.py` assumes that the
real and imaginary parts returned by `_eval_evalf(...).as_real_imag()` are
either exact zero or numeric. For expressions such as `Max(0, y)`, the real
part can remain symbolic and nonzero. In that case the fallback did not assign
`reprec` or `imprec`, so assembling the evalf result tuple could raise
`UnboundLocalError`.

The argument order mattered because a preceding unevaluable symbol caused
`evalf_mul` to abandon numerical evaluation before reaching `Max`, while a
leading `Max` entered this incomplete fallback path first.

## Files changed

`repo/sympy/core/evalf.py`

Added explicit `NotImplementedError` branches when a nonzero real or imaginary
component is not numeric. This keeps the internal evalf tuple restricted to
mpf-valued components or `None` for exact zero, and lets the existing public
`evalf` fallback preserve symbolic expressions instead of crashing.

## Assumptions and alternatives considered

I assumed the internal evalf tuple contract documented at the top of
`evalf.py` is authoritative: `re` and `im` should be nonzero mpf tuples, or
`None` to denote exact zero. The precision fields only describe those numeric
components.

I rejected setting only `reprec` or `imprec` to `None` for symbolic components,
because that would still leave a symbolic expression in a tuple position that
callers treat as an mpf tuple. I also rejected converting symbolic nonnumeric
components to `None`, because that would incorrectly treat unevaluable
expressions as exact zero.

I did not run tests or execute project code, following the benchmark
constraints.
