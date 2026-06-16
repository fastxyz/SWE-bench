# Baseline Notes

## Root cause

`polylog` had two gaps in `sympy/functions/special/zeta_functions.py`:

1. `polylog.eval` recognized only the special arguments `z = 0`, `z = 1`, and `z = -1`, so the standard value `polylog(2, 1/2) = pi**2/12 - log(2)**2/2` remained unevaluated.
2. `_eval_expand_func` expanded `polylog(1, z)` as `-log(1 + exp_polar(-I*pi)*z)`. That encodes the same numerical branch after replacing `exp_polar` by `exp`, but the polar factor is unnecessary inside `1 + ...` and prevents routine symbolic simplification such as comparing derivatives against `-log(1 - z)`.

## Files changed

`repo/sympy/functions/special/zeta_functions.py`

- Added the closed form for `polylog(2, S.Half)` in `polylog.eval`, so direct construction and function expansion both see the known dilogarithm value.
- Changed the `polylog(1, z)` functional expansion to `-log(1 - z)`, matching the ordinary logarithmic identity without introducing an irrelevant `exp_polar` factor.
- Updated the adjacent docstring example for `expand_func(polylog(1, z))`.

## Assumptions and alternatives considered

- I assumed the issue asks for the concrete known value at `z = 1/2`, not a broader dilogarithm simplification system. Adding only this value keeps the change targeted.
- I put the `polylog(2, 1/2)` value in `eval` instead of `_eval_expand_func` because the issue describes this as an evaluation gap and the class already evaluates other special `z` values directly.
- I considered preserving `exp_polar(-I*pi)` for branch tracking, but rejected it for the order-one expansion because the issue specifically identifies that polar factor as the source of incorrect symbolic behavior and states that `polylog(1, z)` should be represented as `-log(1 - z)`.
- I did not modify tests or run the test suite, per the benchmark instructions.
