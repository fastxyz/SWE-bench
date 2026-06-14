# Baseline notes — sympy__sympy-13852

## Issue summary

The GitHub issue raises two related complaints about `polylog`:

1. **Missing evaluation.** `polylog(2, Rational(1, 2)).expand(func=True)` returns the
   input unchanged, but it should evaluate to the well-known special value
   `Li_2(1/2) = pi**2/12 - log(2)**2/2`.
2. **Spurious `exp_polar`.** `expand_func(polylog(1, z))` returns
   `-log(z*exp_polar(-I*pi) + 1)`. The `exp_polar(-I*pi)` factor is just `-1`
   carrying polar (winding-number) information, but here that information is about
   a winding around `z = 1`, where `log` is *not* branched, so it is meaningless.
   The polylogarithm `polylog(1, z)` is identically `-log(1 - z)` (same power
   series for `|z| < 1`, same branch cut at `1`, numerically equal everywhere per
   the issue's testing). The stray `exp_polar` even breaks `expand_func`'s
   consistency with differentiation:
   `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))` did not
   simplify to `0`.

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
    return polylog(s, z)                       # <-- no s == 2, z == 1/2 case
```

- The `s == 1` branch deliberately introduced `exp_polar(-I*pi)` instead of just
  returning `-log(1 - z)`.
- There was no special case for the closed-form value of `Li_2(1/2)`, so
  `polylog(2, 1/2)` fell through to the final `return polylog(s, z)` (a no-op).

## Changes made

### `repo/sympy/functions/special/zeta_functions.py`

1. **`polylog._eval_expand_func`**
   - Changed the `s == 1` branch from `return -log(1 + exp_polar(-I*pi)*z)` to
     `return -log(1 - z)`. This removes the meaningless polar factor and makes
     `expand_func` consistent with differentiation. It also matches the rest of
     SymPy: `hyperexpand` already returns `-log(1 - z)` for the equivalent
     hypergeometric form (`sympy/simplify/tests/test_hyperexpand.py:582`).
   - Added a special case `if s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12`,
     giving the closed form for `Li_2(1/2)`.
   - Removed `exp_polar` and `I` from the function-local
     `from sympy import ...` line, since they are no longer used (`pi` is already
     imported at module scope and is used by the new branch; `log`, `expand_mul`,
     `Dummy` are still used by the remaining branches).

2. **`polylog` docstring**
   - Updated the doctest `expand_func(polylog(1, z))` output from
     `-log(z*exp_polar(-I*pi) + 1)` to `-log(-z + 1)` (the str form of
     `-log(1 - z)`; cf. the neighbouring `polylog(0, z)` example which prints
     `z/(-z + 1)`).
   - Added a doctest documenting the new evaluation:
     `expand_func(polylog(2, S.Half))` -> `-log(2)**2/2 + pi**2/12`.

These are the only non-test source changes. No test files were modified.

## Why the new behaviour is correct

- `Li_2(1/2) = pi**2/12 - log(2)**2/2` is a standard dilogarithm identity
  (numerically ~0.5822405, matching `pi**2/12 - log(2)**2/2`). This also agrees
  with the issue's own `nsimplify(... )` cross-check.
- `polylog(1, z) = -log(1 - z)`: for `|z| < 1` this is the series
  `sum_{n>=1} z**n/n`; the analytic continuations share the branch cut on
  `[1, infinity)` (e.g. for real `z > 1` both have imaginary part `-pi`, as the
  issue verified against mpmath at many random points). Derivative consistency
  now holds: `diff(polylog(1, z)) = polylog(0, z)/z`, which expands to
  `1/(1 - z) = diff(-log(1 - z))`.

## Assumptions and alternatives considered

- **Where to add the `Li_2(1/2)` value — `eval` vs `_eval_expand_func`.**
  Chosen: `_eval_expand_func`. The issue demonstrates the bug with
  `.expand(func=True)` and shows `polylog(2, 1/2)` deliberately staying
  unevaluated by default (`Out[1]: polylog(2, 1/2)`). Putting the value in
  `eval` would auto-evaluate it and change the default display, which the issue
  does not ask for. Rejected.

- **Keeping polar information for `|z| > 1` "correctness".**
  Rejected. The issue establishes (and SymPy's `hyperexpand` already assumes)
  that `polylog(1, z)` and `-log(1 - z)` are the same function including branch
  cuts. The polar factor here encodes winding about `z = 1`, where `log` is
  unbranched, so it is genuinely meaningless.

- **A broader special-value table for `polylog`.**
  Rejected as out of scope. The task asks for a minimal, targeted fix; only the
  `s == 2, z == 1/2` value is required by the issue.

- **Edge cases of the guard `s == 2 and z == S.Half`.**
  For symbolic `s`/`z` the conditions are `False` and the function falls through
  to the existing behaviour, so general expansions are unaffected (verified that
  `polylog(2, z)` with symbolic `z` and `polylog(3, ...)` in
  `test_hyperexpand.py` are untouched). A `Float(0.5)` argument compares equal to
  `S.Half` and would also return the exact value, which is harmless.
