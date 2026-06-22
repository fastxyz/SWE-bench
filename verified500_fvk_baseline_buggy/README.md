# Verified500 FVK Baseline-Buggy Cases

This directory contains the 16 confirmed cases where:

- the baseline arm resolved the official SWE-bench tests;
- the FVK arm also resolved the official SWE-bench tests;
- the baseline patch still had a concrete correctness bug; and
- the FVK patch fixed that bug with an explicit formal-verification argument.

Each case has an `ANALYSIS.md` file with the baseline defect, the concrete
failure mode, the FVK proof argument, and the gold or source-level comparison.
Some case directories also include `_materials/` and regression-test files used
by the earlier audit.

## Cases

1. [pydata__xarray-4094](pydata__xarray-4094/ANALYSIS.md)
2. [sphinx-doc__sphinx-9367](sphinx-doc__sphinx-9367/ANALYSIS.md)
3. [django__django-13121](django__django-13121/ANALYSIS.md)
4. [django__django-14170](django__django-14170/ANALYSIS.md)
5. [sympy__sympy-14531](sympy__sympy-14531/ANALYSIS.md)
6. [sympy__sympy-24066](sympy__sympy-24066/ANALYSIS.md)
7. [django__django-11206](django__django-11206/ANALYSIS.md)
8. [django__django-13569](django__django-13569/ANALYSIS.md)
9. [django__django-14725](django__django-14725/ANALYSIS.md)
10. [matplotlib__matplotlib-25960](matplotlib__matplotlib-25960/ANALYSIS.md)
11. [scikit-learn__scikit-learn-13496](scikit-learn__scikit-learn-13496/ANALYSIS.md)
12. [astropy__astropy-14096](astropy__astropy-14096/ANALYSIS.md)
13. [psf__requests-2931](psf__requests-2931/ANALYSIS.md)
14. [django__django-11095](django__django-11095/ANALYSIS.md)
15. [pydata__xarray-4695](pydata__xarray-4695/ANALYSIS.md)
16. [sphinx-doc__sphinx-9229](sphinx-doc__sphinx-9229/ANALYSIS.md)

## Evidence Standard

The retained cases are not merely "different correct solutions." They are the
stricter category where the baseline result passed the benchmark but remained
buggy. The FVK result fixed the bug by enforcing a specific proof obligation,
such as a frame condition, public API compatibility condition, dispatch
invariant, or rebuild-dependency invariant.
