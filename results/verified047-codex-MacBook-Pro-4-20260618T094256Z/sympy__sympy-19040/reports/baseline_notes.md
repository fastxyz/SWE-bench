# Baseline Notes

## Root cause

`dmp_ext_factor` first reduced the multivariate polynomial with
`dmp_sqf_part` before computing the square-free norm used for factoring over
an algebraic extension. For multivariate dense polynomials this square-free
part is taken with respect to the main variable. A factor that depends only on
lower variables, such as `y - 1` in `(x - 1)*(y - 1)`, is treated as content in
the main variable and is removed from the polynomial passed to
`dmp_sqf_norm`. Because the removed factor never appears in the norm-derived
candidate list, the final trial division can only recover the `x - 1` factor.

## Changed files

`repo/sympy/polys/factortools.py`

- Updated `dmp_ext_factor` to split out the main-variable content with the
  existing `dmp_primitive` helper before applying `dmp_sqf_part`.
- Factored that content recursively with `dmp_factor_list` in the lower
  variable ring and lifted those factors back into the full variable set with
  `dmp_include`.
- Preserved the existing norm-based extraction for the primitive part and
  kept final multiplicity calculation in `dmp_trial_division`.

## Assumptions and alternatives

- I assumed the intended behavior is to factor all multivariate factors over
  the requested algebraic extension, including factors independent of the main
  variable. This matches the reported `factor((x - 1)*(y - 1), extension=[I])`
  case and existing factorization semantics.
- I considered changing `dmp_sqf_part` itself, but that helper's current
  behavior is used elsewhere and its documented examples are main-variable
  oriented. Changing it would have a broader behavioral surface than needed.
- I considered bypassing `dmp_sqf_part` in `dmp_ext_factor`, but that would
  feed repeated primitive factors into the norm algorithm and would lose the
  existing square-free optimization. Splitting and recursively factoring the
  main-variable content is more targeted.
- I did not add or modify tests, and I did not run SymPy or the test suite, per
  the task constraints.
