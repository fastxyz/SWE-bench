# Baseline notes — sympy__sympy-13852: "Add evaluation for polylog"

## Summary of the issue

The GitHub issue raises two related complaints about `polylog`, both centered on
`polylog._eval_expand_func` (i.e. what `expand_func` / `.expand(func=True)` does):

1. **Missing dilogarithm value.** `polylog(2, Rational(1, 2)).expand(func=True)`
   returned `polylog(2, 1/2)` unchanged, whereas the well-known closed form is
   `Li_2(1/2) = pi**2/12 - log(2)**2/2`.

2. **Spurious `exp_polar` in `polylog(1, z)`.** `expand_func(polylog(1, z))`
   returned `-log(z*exp_polar(-I*pi) + 1)`. `polylog(1, z)` is exactly `-log(1 - z)`
   (same power series for `|z| < 1`, same branch cut at `z = 1`), so the
   `exp_polar(-I*pi)` (which equals `-1`) carries no useful information. Worse, it
   tracks a winding number about `1`, and `log` is *not* branched at `1`, so the
   factor is meaningless there. It also broke derivative consistency: with the old
   form,
   `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))`
   did not simplify to `0` because the derivative of
   `-log(1 + exp_polar(-I*pi)*z)` is `-exp_polar(-I*pi)/(1 + exp_polar(-I*pi)*z)`,
   which the system will not cancel against `1/(1 - z)`.

## Root cause

Both problems live in `polylog._eval_expand_func` in
`repo/sympy/functions/special/zeta_functions.py`:

- The `s == 1` branch returned `-log(1 + exp_polar(-I*pi)*z)` instead of the
  equivalent, simpler, branch-correct `-log(1 - z)`.
- There was no branch handling the dilogarithm special value at `z = 1/2`, so the
  generic fall-through `return polylog(s, z)` left it unevaluated.

## Files changed

### `repo/sympy/functions/special/zeta_functions.py`

`polylog._eval_expand_func`:

- Changed the `s == 1` case from `-log(1 + exp_polar(-I*pi)*z)` to `-log(1 - z)`.
  This removes the meaningless polar factor and restores derivative consistency:
  `d/dz(-log(1 - z)) = 1/(1 - z)`, which matches
  `expand_func(polylog(1, z).diff(z)) = expand_func(polylog(0, z)/z) = 1/(1 - z)`.
- Added a special-value branch for the dilogarithm:
  `if z == S(1)/2: if s == 2: return -log(2)**2/2 + pi**2/12`.
  This is placed in `_eval_expand_func` (not in `eval`) so that
  `polylog(2, Rational(1, 2))` stays unevaluated until the user explicitly calls
  `expand_func` / `.expand(func=True)`, matching the behavior shown in the issue.
- Dropped the now-unused `exp_polar, I` names from the method's local
  `from sympy import ...` line (`pi` and `S` come from the module-level import on
  line 4; `log` stays in the local import).

`polylog` docstring: updated the doctest

```
>>> expand_func(polylog(1, z))
-log(-z + 1)
```

(`1 - z` prints as `-z + 1`, consistent with the neighbouring
`expand_func(polylog(0, z)) -> z/(-z + 1)` example) so the doctest stays in sync
with the new behavior.

## Assumptions and rejected alternatives

- **Put the `Li_2(1/2)` value in `eval` (auto-evaluate)?** Rejected. The issue
  transcript explicitly shows `polylog(2, Rational(1,2))` returning
  `polylog(2, 1/2)` and only `.expand(func=True)` producing the closed form, so the
  value belongs in `_eval_expand_func`, not in the auto-evaluating `eval`.

- **Keep `exp_polar` but `unpolarify` it?** Rejected. The issue argues (correctly)
  that the polar/winding information is meaningless here because `log` is unbranched
  at `1`; `-log(1 - z)` is the simplest correct, derivative-consistent form and is
  what the reporter asks for.

- **Impact on `lerchphi._eval_expand_func` and `hyperexpand`.** Checked. The Lerch
  reduction (`lerchphi._eval_expand_func`) calls `polylog(s, ...)._eval_expand_func`
  only with a *symbolic* order `s`, which falls through to `return polylog(s, z)`
  and is unchanged. `hyperexpand` produces `lerchphi`/`polylog`/`-log(1 - z)` forms
  directly (e.g. `hyperexpand(z*hyper([1, 1], [2], z)) == -log(1 + -z)`), not via
  `polylog._eval_expand_func`, so it is unaffected. No other module uses the old
  `exp_polar(-I*pi)` polylog form (`meijerint` has no `polylog` reference).

- **Add `_eval_evalf` for numeric `polylog`?** Not done. Numeric evaluation already
  works generically (the existing `td(polylog(b, z), z)` derivative test relies on
  it), and the issue's scope is symbolic expansion via `expand_func`. Keeping the
  change minimal avoids unrelated behavior changes.

## Net effect

```
>>> expand_func(polylog(1, z))
-log(-z + 1)
>>> polylog(2, Rational(1, 2)).expand(func=True)
-log(2)**2/2 + pi**2/12
>>> expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))
0
```
