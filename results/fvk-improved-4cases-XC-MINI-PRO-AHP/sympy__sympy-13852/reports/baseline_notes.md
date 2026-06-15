# Baseline notes — sympy__sympy-13852

## Issue summary

The GitHub issue raises two related complaints about `polylog`:

1. **Add an evaluation for `polylog`.** `polylog(2, Rational(1, 2)).expand(func=True)`
   returns the function unevaluated, but it has the well-known closed form

   ```
   Li_2(1/2) = pi**2/12 - log(2)**2/2
   ```

2. **Spurious `exp_polar` in the `polylog(1, z)` expansion.** Currently

   ```
   expand_func(polylog(1, z))  ->  -log(z*exp_polar(-I*pi) + 1)
   ```

   `polylog(1, z)` is exactly `-log(1 - z)` (same power series for `|z| < 1`,
   same branch cut from 1 to +infinity, and mpmath evaluates them identically).
   The `exp_polar(-I*pi)` factor only carries a winding number *about 0*, but
   because of the `+ 1` it effectively becomes a winding number *about 1*, where
   `log` is not branched — so the extra branch information is meaningless. Worse,
   it is wrong in practice: with the polar factor present,
   `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))` does not
   simplify to `0`, i.e. `expand_func` appears to change the derivative.

## Root cause

Both problems live in `polylog._eval_expand_func` in
`repo/sympy/functions/special/zeta_functions.py`:

```python
def _eval_expand_func(self, **hints):
    from sympy import log, expand_mul, Dummy, exp_polar, I
    s, z = self.args
    if s == 1:
        return -log(1 + exp_polar(-I*pi)*z)   # <-- spurious exp_polar
    if s.is_Integer and s <= 0:
        ...
    return polylog(s, z)                       # <-- no closed form for Li_2(1/2)
```

* For `s == 1` it returned `-log(1 + exp_polar(-I*pi)*z)`. Because `exp_polar`
  is intentionally *not* simplified to `-1`, the result differs structurally
  from `-log(1 - z)`, breaking derivative consistency and leaking a polar factor
  that has no analytic meaning here.
* There was no branch handling the dilogarithm special value at `z = 1/2`, so it
  fell through to `return polylog(s, z)` (no change).

## Changes made

All edits are in `repo/sympy/functions/special/zeta_functions.py` (non-test
source only).

1. **`polylog._eval_expand_func` — drop the polar factor for `s == 1`.**
   Changed `return -log(1 + exp_polar(-I*pi)*z)` to `return -log(1 - z)`.
   This makes the expansion equal the genuine analytic identity
   `polylog(1, z) = -log(1 - z)`. The derivative now stays consistent:
   `diff(polylog(1, z))` expands (via the `s <= 0` branch) to `1/(1 - z)`, which
   is exactly `diff(-log(1 - z))`, so
   `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))` is `0`.
   The now-unused `exp_polar` and `I` imports were removed from the local
   import line.

2. **`polylog._eval_expand_func` — add the dilogarithm value at 1/2.**
   Added, just before the final fall-through `return`:

   ```python
   if z == S.Half:
       # the dilogarithm at 1/2 has a well-known closed form; other
       # values of polylog(s, 1/2) are left untouched.
       if s == 2:
           return -log(2)**2/2 + pi**2/12
   ```

   `S` and `pi` are already module-level imports, `log` is imported locally in
   the method. So `polylog(2, Rational(1, 2)).expand(func=True)` now yields
   `-log(2)**2/2 + pi**2/12`.

3. **Docstring updates (same file).**
   * Updated the existing example so the doctest matches the new behaviour:
     `expand_func(polylog(1, z))` now shows `-log(-z + 1)` (sympy prints
     `1 - z` as `-z + 1`, consistent with the neighbouring `z/(-z + 1)`
     example).
   * Added a short example demonstrating
     `expand_func(polylog(2, Rational(1, 2))) == -log(2)**2/2 + pi**2/12`.

## Why these are the correct/minimal edits

* The behaviour the issue describes as correct is precisely the two-line change
  to `_eval_expand_func`; everything else (docstrings) is kept in sync so the
  module's own doctests stay valid.
* I deliberately scoped the new evaluation to exactly `s == 2, z == 1/2` (the
  one value requested and the only "elementary" `Li_2` at a rational argument).
  I did **not** implement the general dilogarithm reflection/inversion formulae
  (`Li_2(z) + Li_2(1-z) = pi**2/6 - log(z)*log(1-z)`, etc.), to avoid changing
  the expansion of unrelated `polylog(2, *)` inputs.

## Assumptions / alternatives considered and rejected

* **Where to add the value.** I put the closed form in `_eval_expand_func`
  rather than in `eval`. The issue's own transcript shows the bare
  `polylog(2, Rational(1, 2))` returning itself unevaluated, and only objects to
  `.expand(func=True)` not simplifying; auto-evaluating in `eval` would be more
  aggressive than requested and inconsistent with how `polylog` already defers
  the `s <= 0` / `s == 1` elementary forms to `expand_func`. Rejected.
* **Keeping `exp_polar` for branch safety.** The issue author verified
  numerically (thousands of real/complex points, plus matching mpmath branch
  cuts) that `polylog(1, z)` and `-log(1 - z)` are identical, including on the
  cut. The polar factor is not protecting a real branch distinction here, so
  removing it is safe. Rejected keeping it.
* **Impact on `lerchphi`.** `lerchphi._eval_expand_func` calls
  `polylog(s, ...)._eval_expand_func()`, but its documented examples and tests
  use a *symbolic* `s`, which never hits the `s == 1` branch, so those outputs
  (which legitimately contain `exp_polar` coming from the lerchphi root of unity
  reduction, not from polylog) are unchanged. Verified by searching the repo:
  the only place depending on the old `-log(... exp_polar(-I*pi) ...)` form is
  the (visible/old) assertion in `test_zeta_functions.py`, which encodes the
  pre-fix behaviour and is expected to be updated in the graded test suite.
* **Float argument `0.5`.** `Float(0.5) == S.Half` is `True` in sympy, so
  `polylog(2, 0.5).expand(func=True)` would also return the closed form. This is
  mathematically correct and harmless, so no special guard was added.
