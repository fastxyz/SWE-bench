# Verified500 FVK Baseline-Buggy Cases

This directory is an article-oriented evidence set for 16 confirmed cases where
both arms passed the official SWE-bench evaluation, but the baseline patch still
had a concrete correctness bug that the FVK patch fixed.

The intended article claim is simple: SWE-bench hidden tests are useful, but
passing them is not the same thing as semantic correctness. These cases are the
small stories behind that claim.

## Case Documents

1. [pydata__xarray-4094](pydata__xarray-4094.md) - human fix issue: yes; Human fix also loses legitimate size-1 dimensions.
2. [sphinx-doc__sphinx-9367](sphinx-doc__sphinx-9367.md) - human fix issue: yes; Human fix misses the one-element tuple subscript path.
3. [django__django-13121](django__django-13121.md) - human fix issue: yes; Human fix still fails nested duration arithmetic.
4. [django__django-14170](django__django-14170.md) - human fix issue: yes; Human fix still overflows at ISO year 9999.
5. [sympy__sympy-14531](sympy__sympy-14531.md) - human fix issue: partial; FVK and human fix overlap, each covers some extra printer paths.
6. [sympy__sympy-24066](sympy__sympy-24066.md) - human fix issue: yes; Human fix still leaks low-level TypeError in related dimension paths.
7. [django__django-11206](django__django-11206.md) - human fix issue: no; FVK aligns with the human fix on zero Decimal formatting.
8. [django__django-13569](django__django-13569.md) - human fix issue: no; Different mechanism, same preservation of correlated subquery grouping.
9. [django__django-14725](django__django-14725.md) - human fix issue: no; FVK matches the human fix at the public `save()` enforcement point.
10. [matplotlib__matplotlib-25960](matplotlib__matplotlib-25960.md) - human fix issue: no; Different mechanism, same spacing boundary as the human fix.
11. [scikit-learn__scikit-learn-13496](scikit-learn__scikit-learn-13496.md) - human fix issue: no; FVK is behaviorally equivalent to gold; gold adds only documentation.
12. [astropy__astropy-14096](astropy__astropy-14096.md) - human fix issue: no; FVK matches gold behavior by respecting the full MRO.
13. [psf__requests-2931](psf__requests-2931.md) - human fix issue: no; FVK is behaviorally aligned with gold at the shared encoder helper.
14. [django__django-11095](django__django-11095.md) - human fix issue: no; Gold independently supports FVK's static validation boundary.
15. [pydata__xarray-4695](pydata__xarray-4695.md) - human fix issue: partial; Gold fixes direct `.loc`; FVK applies the same invariant to internal dynamic selection helpers.
16. [sphinx-doc__sphinx-9229](sphinx-doc__sphinx-9229.md) - human fix issue: no; Gold uses a different implementation path; FVK fixes a baseline-specific dependency bug.

## Evidence Standard

Each case document is self-contained and includes:

- the benchmark outcome;
- the baseline bug;
- why the hidden tests missed it;
- the FVK formal argument;
- the relationship to the human gold fix.

The FVK proof status is reported conservatively. When the underlying FVK run was
constructed but not machine-checked, the case should be cited as
proof-structured evidence rather than a completed `kprove` result.
