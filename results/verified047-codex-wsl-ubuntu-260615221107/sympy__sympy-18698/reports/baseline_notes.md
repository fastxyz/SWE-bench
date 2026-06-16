# Baseline Notes

## Root cause

The public `sqf_list()` helper in `sympy/polys/polytools.py` routes expression
inputs through `_generic_factor_list()` and `_symbolic_factor_list()`. For a
factored expression, `_symbolic_factor_list()` processes each multiplicative
piece separately, so factors with the same square-free multiplicity are appended
as separate list entries. The lower-level `Poly.sqf_list()` path works on the
whole polynomial representation and returns one factor for each multiplicity.

As a result, an already-factored univariate expression like
`(x**2 + 1)*(x - 1)**2*(x - 2)**3*(x - 3)**3` could return both `(x - 3, 3)`
and `(x - 2, 3)` instead of combining them as `(x**2 - 5*x + 6, 3)`.

## Files changed

`repo/sympy/polys/polytools.py`

- Added `_combine_factors()` to multiply factors that share the same exponent
  after `_generic_factor_list()` has normalized them to `Poly` instances.
- Added `_sqf_list_should_combine()` so grouping is applied to square-free list
  output only when the input is univariate or the caller supplied an explicit
  single generator. This fixes the reported univariate inconsistency without
  changing the existing ambiguous multivariate symbolic behavior when no
  generator is provided.
- Applied the grouping only for `method == 'sqf'`; ordinary `factor_list()`
  still returns irreducible factors separately.
- Updated the public `sqf_part()`, `sqf_list()`, and `sqf()` docstrings to state
  that these helpers operate on univariate polynomials.

## Assumptions and alternatives considered

I assumed the requested behavior is that expression-level `sqf_list()` should
match the `Poly.sqf_list()` convention for univariate inputs: one returned
factor per multiplicity. I also assumed that `factor_list()` must not be changed,
because its purpose is to expose irreducible factors rather than square-free
multiplicity groups.

I considered rewriting `sqf_list()` to construct a `Poly` up front and delegate
directly to `Poly.sqf_list()`. I rejected that as a broader behavioral change
because the current expression helper also handles symbolic factor traversal,
fraction handling, and the `polys` flag through `_generic_factor_list()`.

I also considered raising an error for multivariate expressions with no explicit
generator, as discussed in the issue thread. I rejected that here because it
would change existing behavior beyond the reported inconsistency. The implemented
change leaves that case alone while still grouping when the caller gives a
single generator explicitly.
