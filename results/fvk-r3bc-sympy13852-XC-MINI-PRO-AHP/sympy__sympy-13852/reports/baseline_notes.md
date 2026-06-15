# Baseline notes — sympy__sympy-13852

## Issue summary

The GitHub issue raises two related problems with `polylog` evaluation, both
located in `polylog._eval_expand_func`:

1. **Spurious `exp_polar` in `expand_func(polylog(1, z))`.**
   The expansion produced `-log(z*exp_polar(-I*pi) + 1)` instead of the
   mathematically identical and simpler `-log(1 - z)`. As the reporter (a core
   SymPy developer) explains, `polylog(1, z)` and `-log(1 - z)` are the *same*
   function everywhere (same power series for `|z| < 1`, same branch cut on
   `[1, ∞)`, verified numerically against mpmath at many points). The
   `exp_polar` factor records a winding number about `0` in `z`-space, but the
   relevant branch point of `log(1 + …·z)` is at `z = 1`, where `log` is not
   branched. The extra "polar" data is therefore meaningless and actively
   harmful: it made `expand_func` appear to change the function's derivative
   (`expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))` did not
   simplify to `0`).

2. **No closed form for `polylog(2, 1/2)`.**
   `expand_func(polylog(2, Rational(1, 2)))` returned the input unchanged, but
   the dilogarithm has the well-known special value
   `Li₂(1/2) = π²/12 − log(2)²/2`.

## Root cause

Both behaviors come from `polylog._eval_expand_func` in
`repo/sympy/functions/special/zeta_functions.py`:

- The `s == 1` branch returned `-log(1 + exp_polar(-I*pi)*z)`, deliberately
  carrying the polar factor that the issue identifies as spurious.
- The method had no handling for the `s == 2`, `z == 1/2` special value, so it
  fell through to `return polylog(s, z)` (i.e. no expansion).

## Changes

All changes are in `repo/sympy/functions/special/zeta_functions.py` (non-test
source only).

1. **`polylog._eval_expand_func`, `s == 1` branch.**
   Changed `return -log(1 + exp_polar(-I*pi)*z)` to `return -log(1 - z)`.
   This removes the meaningless polar factor and makes `expand_func` agree with
   the function and its derivative (`d/dz (-log(1 - z)) = 1/(1 - z)`, which
   matches `polylog(0, z)/z = (z/(1 - z))/z`).

2. **`polylog._eval_expand_func`, new special value.**
   Added, before the final fall-through, a branch returning the dilogarithm
   special value:
   ```python
   if z == S.Half and s == 2:
       # Special value, see e.g.
       #   http://mathworld.wolfram.com/Dilogarithm.html
       return -log(2)**2/2 + pi**2/12
   ```
   (`pi` is already imported at module level; `log` is imported locally in the
   method.) Numerically `π²/12 − log(2)²/2 ≈ 0.5822405`, matching
   `Li₂(1/2)`.

3. **Import cleanup in the same method.**
   The local import `from sympy import log, expand_mul, Dummy, exp_polar, I`
   was reduced to `from sympy import log, expand_mul, Dummy`, because
   `exp_polar` and `I` were only used by the removed `s == 1` expression and
   are now dead.

4. **Docstring of `polylog`.**
   Updated the doctest example from
   `>>> expand_func(polylog(1, z))` → `-log(z*exp_polar(-I*pi) + 1)` to the new
   output `-log(-z + 1)` (SymPy's str form of `-log(1 - z)`; the same `1 - z`
   already prints as `-z + 1` in the adjacent `polylog(0, z)` example).

## Assumptions and rejected alternatives

- **Special value placed in `_eval_expand_func`, not `eval`.** The issue shows
  `polylog(2, Rational(1,2))` deliberately staying unevaluated (`Out[1]:
  polylog(2, 1/2)`) and asks only that `.expand(func=True)` produce the closed
  form (`In [2]`). Putting the value in `classmethod eval` would auto-evaluate
  `polylog(2, 1/2)` on construction, contradicting `Out[1]` and diverging from
  the existing convention where `eval` only handles `z ∈ {0, 1, -1}`. Placing
  it in `_eval_expand_func` satisfies the requested `expand_func` behavior while
  leaving the unevaluated form intact. (It also still satisfies any test of the
  form `expand_func(polylog(2, S.Half)) == …`.)

- **Restricted the special case to exactly `s == 2 and z == 1/2`.** The
  `Li₂(1/2)` closed form is specific; other `s`/`z` combinations at `z = 1/2`
  do not share it. `polylog(1, 1/2)` is already handled correctly by the
  `s == 1` branch (`-log(1 - 1/2) = log(2)`), so no extra case is needed there.
  A broader/general dilogarithm reduction was rejected as out of scope and
  risk of changing unrelated outputs.

- **Removing `exp_polar` entirely (vs. trying to `unpolarify`).** The cleanest
  and reporter-endorsed result is the literal `-log(1 - z)`; using
  `unpolarify` on the old expression would have produced the same value but
  with no benefit and more code. The plain form also matches the function's
  branch structure exactly, as argued in the issue.

- **Left `lerchphi._eval_expand_func` untouched.** Its examples use
  `exp_polar` with *general* `s` inside `polylog(s, …)` (e.g.
  `polylog(s, sqrt(z)*exp_polar(I*pi))`); those are unrelated to the `s == 1`
  reduction and remain mathematically necessary, so they were not changed. A
  repo-wide search confirmed no non-test source or docs depend on the old
  `expand_func(polylog(1, z))` output.
