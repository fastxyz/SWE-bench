# Baseline notes — sympy__sympy-13852

## Issue summary

Two related defects in `polylog` (the polylogarithm `Li_s(z)`):

1. **Missing evaluation.** `polylog(2, Rational(1,2)).expand(func=True)` returned the
   unevaluated `polylog(2, 1/2)` instead of the well‑known closed form
   `Li_2(1/2) = pi**2/12 - log(2)**2/2`.

2. **Spurious `exp_polar` in `polylog(1, z)`.** `expand_func(polylog(1, z))` returned
   `-log(z*exp_polar(-I*pi) + 1)`. The `exp_polar(-I*pi)` factor is meaningless here:
   `polylog(1, z)` is identically `-log(1 - z)` (same power series for `|z| < 1`, same
   branch cut on `[1, ∞)`, same boundary values — imaginary part `-pi` for real `z > 1`).
   The polar factor encodes a winding number about `0`, which becomes a winding number
   about `1` after the `+ 1`; but `log` is not branched at `1`, so the information is
   irrelevant. Worse, it blocks simplification: derivative‑consistency checks such as
   `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))` failed to reduce to
   `0` because `exp_polar(-I*pi)` is never simplified to `-1` automatically.

## Root cause

Both defects live in `polylog._eval_expand_func` in
`repo/sympy/functions/special/zeta_functions.py`:

- The `s == 1` branch returned `-log(1 + exp_polar(-I*pi)*z)` — an over‑cautious polar
  lift that is not needed since `log` is unbranched at `1`.
- There was no branch for the dilogarithm special value at `z = 1/2`, so
  `polylog(2, 1/2)` had no expansion rule and fell through to the unevaluated
  `return polylog(s, z)`.

## Changes made

All edits are in `repo/sympy/functions/special/zeta_functions.py` (non‑test source only).

1. **`polylog._eval_expand_func`, `s == 1` branch.**
   Changed `return -log(1 + exp_polar(-I*pi)*z)` to `return -log(1 - z)`.
   This makes the expansion equal to the function it represents, restoring
   derivative consistency and removing the meaningless polar factor.

2. **`polylog._eval_expand_func`, new dilogarithm special value.**
   Added, before the final `return polylog(s, z)`:
   ```python
   # special value of the dilogarithm at z = 1/2
   if s == 2 and z == S.Half:
       return -log(2)**2/2 + pi**2/12
   ```
   so that `polylog(2, S.Half).expand(func=True)` yields `-log(2)**2/2 + pi**2/12`
   (matching the value obtained numerically in the issue). `S` and `pi` are already
   imported at module level.

3. **Removed now‑dead local imports.** The method’s local import line was
   `from sympy import log, expand_mul, Dummy, exp_polar, I`. With `exp_polar`/`I` no
   longer used it became `from sympy import log, expand_mul, Dummy`.

4. **Docstring doctest.** The `polylog` class docstring demonstrated the old behavior:
   ```
   >>> expand_func(polylog(1, z))
   -log(z*exp_polar(-I*pi) + 1)
   ```
   Updated to the new printed form `-log(-z + 1)` (SymPy prints `1 - z` as `-z + 1`,
   consistent with the neighbouring `polylog(0, z)` doctest `z/(-z + 1)`).

## Why this is safe for the `lerchphi` reduction path

`lerchphi._eval_expand_func` calls `polylog(s, zet**k*root)._eval_expand_func(**hints)`.
For the tested cases `s` is a free symbol, so the new `s == 1` and `s == 2, z == 1/2`
branches are never taken and the output is unchanged. Even at the (untested) integer
`s == 1`, I traced `lerchphi(z, 1, 1/2)`: the new form
`-log(1 - sqrt(z))/sqrt(z) + log(1 - exp_polar(I*pi)*sqrt(z))/sqrt(z)` unpolarifies to
`(1/sqrt(z))*log((1 + sqrt(z))/(1 - sqrt(z)))`, the correct value — and is numerically
identical (under `exp_polar -> exp`) to the previous output. The independent
`hyperexpand` code path already emits `-log(1 - z)` for `z*hyper([1, 1], [2], z)`
(see `test_hyperexpand.py:582`), so the new convention is consistent with the rest of
the library.

## Assumptions and rejected alternatives

- **Place the `Li_2(1/2)` rule in `expand_func`, not `eval`.** The issue shows
  `polylog(2, Rational(1,2))` deliberately staying unevaluated (In[1]) while
  `.expand(func=True)` produces the answer (In[2]). Auto‑evaluating in the `eval`
  classmethod would change `polylog(2, 1/2)` at construction time, contradicting the
  issue’s shown behavior and SymPy’s convention of keeping such reductions behind
  `expand_func`. Rejected.

- **Only fixing one of the two problems.** The issue is a single report with two parts
  ("Add evaluation for polylog" + the `exp_polar` question); both are addressed.

- **Generalizing `Li_2` special values (e.g. `z = -1`, golden‑ratio arguments) or adding
  more `polylog` closed forms.** Out of scope and against the "minimal, targeted" guidance;
  only the `z = 1/2` value requested in the issue was added. (`z = 1` and `z = -1` are
  already handled for all `s` by `polylog.eval`.)

- **Keeping the polar lift but `unpolarify`-ing it.** Returning `-log(1 - z)` directly is
  simpler, exactly correct, and matches the existing `hyperexpand` output; introducing
  `unpolarify` would be needless indirection.
