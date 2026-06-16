# Baseline Notes

## Root cause

`dmp_ext_factor` normalized a multivariate polynomial over an algebraic
extension and immediately replaced it with `dmp_sqf_part(f, u, K)` before
computing the square-free norm. For multivariate dense polynomials,
`dmp_sqf_part` differentiates with respect to the leading variable. Any factor
that depends only on lower variables, such as `y - 1` in `(x - 1)*(y - 1)`, is
therefore part of the leading-variable content and is divided out by the GCD
with the derivative. The later norm factorization and trial division then only
see the primitive leading-variable part, so `factor(..., extension=[I])` can
return `x - 1` and omit `y - 1`.

## Changed files

`repo/sympy/polys/factortools.py`

The multivariate algebraic-extension path now first splits the monic polynomial
into leading-variable content and primitive part with `dmp_primitive`. The
content is factored recursively in the lower-variable ring and lifted back into
the original level with `[g]`, matching the representation used elsewhere in
multivariate factorization. The existing square-free norm workflow is then
applied only to the primitive part, and its factors are recovered with trial
division against the original monic polynomial so multiplicities are preserved.

## Assumptions and alternatives

I assumed the intended behavior is to preserve all factors over the algebraic
extension, including factors independent of the leading variable, and to keep
the existing square-free norm algorithm for the primitive leading-variable
portion.

I considered changing `dmp_sqf_part` so it would retain lower-variable content,
but rejected that because `dmp_sqf_part` has broader documented behavior and
tests that rely on leading-variable square-free semantics. I also considered
passing the original polynomial directly to `dmp_sqf_norm`, but rejected that
because repeated leading-variable factors can keep the norm non-square-free and
break the purpose of the square-free preprocessing.
