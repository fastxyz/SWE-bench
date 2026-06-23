# Verified500 FVK Baseline-Buggy Cases

This directory is an article-oriented evidence set for verified500 instances
where both the baseline arm and the FVK arm passed the official SWE-bench
evaluation, but the FVK audit found a residual baseline-arm defect.

The claim is narrow: hidden tests are useful, but passing them is not the same
thing as semantic correctness. These documents are the case-level evidence.

## Scope

The source population is the 86 verified500 instances where:

- baseline resolved the official evaluation;
- FVK resolved the official evaluation;
- the FVK patch differed from the baseline patch.

Only cases with a defensible residual baseline code defect receive documents
here. Cases where the FVK delta was a documentation update, refactor, proof
simplification, comment, or otherwise behaviorally equivalent change — with no
residual baseline code defect — are excluded.

## Severity Rubric

- **High:** silently returns wrong results or loses data.
- **Medium:** crashes or behaves incorrectly for a valid, realistic use case.
- **Low:** real issue with limited practical impact because it requires narrow
  trigger conditions, boundary values, or specialized usage.

## Summary

| Severity | Documents |
|---|---:|
| High | 9 |
| Medium | 21 |
| Low | 30 |
| **Total** | **60** |
| Excluded | 26 |

## Report Format

Each case document is self-contained and follows one fixed structure: a Summary
(leading with `**Severity:**`), then six numbered sections — the issue and the
real defect, what baseline did and where it stopped, how FVK formally captured
the gap, how the formal output drove the fix, verification, and honest
boundaries — closing with an Artifact map. Every quoted claim links to its source
artifact under `../results/<run_id>/<instance>/` or
`../verified500_analysis/<instance>/`.

The FVK proof status is reported conservatively: where the K artifacts were
written but not machine-checked, the case is cited as proof-structured reasoning
rather than a completed `kprove` result.

## High

1. [astropy__astropy-14539](astropy__astropy-14539.md) - VLA FITS diff equality can silently report wrong row comparison results.
2. [django__django-11206](django__django-11206.md) - zero-valued Decimals can render as scientific-notation garbage.
3. [django__django-12965](django__django-12965.md) - direct delete can ignore `extra_tables`, risking over-broad deletion.
4. [django__django-13158](django__django-13158.md) - combined `.none()` querysets can silently return rows, violating the empty-query contract.
5. [django__django-13569](django__django-13569.md) - correlated subquery grouping can be silently dropped.
6. [pydata__xarray-4094](pydata__xarray-4094.md) - stack/unstack can silently lose legitimate length-1 dimensions.
7. [pydata__xarray-4966](pydata__xarray-4966.md) - OPeNDAP byte data can be decoded with the wrong signedness.
8. [pylint-dev__pylint-7080](pylint-dev__pylint-7080.md) - package subtree linting can be silently skipped.
9. [scikit-learn__scikit-learn-14496](scikit-learn__scikit-learn-14496.md) - OPTICS fractional thresholds can use the wrong integer counts.

## Medium

1. [astropy__astropy-14096](astropy__astropy-14096.md) - subclass property lookup can take the wrong descriptor/MRO error path.
2. [django__django-11087](django__django-11087.md) - delete-query projection can affect an admin display collector path.
3. [django__django-11095](django__django-11095.md) - objectless inline hooks can reject valid related-object admin paths.
4. [django__django-11292](django__django-11292.md) - command-line `testserver` can skip checks unintentionally.
5. [django__django-12774](django__django-12774.md) - `in_bulk()` can reject a valid unique-constraint lookup through `attname`.
6. [django__django-13121](django__django-13121.md) - duration-producing ORM arithmetic can crash on supported backends.
7. [django__django-13346](django__django-13346.md) - JSON `__in` SQL can be wrong or unusable on Oracle.
8. [django__django-13658](django__django-13658.md) - explicit-argv management parsing can still depend on global `sys.argv`.
9. [django__django-14539](django__django-14539.md) - `urlize()` can still split escaped trailing punctuation incorrectly.
10. [django__django-15916](django__django-15916.md) - ModelForm callback resolution can leak through a replacement `Meta`.
11. [django__django-15957](django__django-15957.md) - unordered sliced prefetches can fail on window-function backends.
12. [matplotlib__matplotlib-25960](matplotlib__matplotlib-25960.md) - unrelated GridSpec spacing can leak into subfigure placement.
13. [matplotlib__matplotlib-26342](matplotlib__matplotlib-26342.md) - contour path replacement can leave stale derived geometry.
14. [pydata__xarray-4695](pydata__xarray-4695.md) - dynamic indexers can collide with `.sel()` keyword names.
15. [scikit-learn__scikit-learn-12585](scikit-learn__scikit-learn-12585.md) - composition parameter expansion can crash on class-valued parameters.
16. [scikit-learn__scikit-learn-14087](scikit-learn__scikit-learn-14087.md) - no-refit logistic-regression coefficient selection can still crash.
17. [sphinx-doc__sphinx-10673](sphinx-doc__sphinx-10673.md) - generated toctree entries can reach source-doctree section numbering.
18. [sphinx-doc__sphinx-9602](sphinx-doc__sphinx-9602.md) - `Literal[...]` values can still create false cross-reference warnings.
19. [sympy__sympy-12096](sympy__sympy-12096.md) - recursive `_imp_` evalf still has raw-return and unresolved-function gaps.
20. [sympy__sympy-14531](sympy__sympy-14531.md) - printer options can be dropped across expression families.
21. [sympy__sympy-22714](sympy__sympy-22714.md) - valid real `Point` coordinates can be rejected under `evaluate(False)`.

## Low

1. [astropy__astropy-7166](astropy__astropy-7166.md) - read-only descriptor doc assignment can abort class creation.
2. [django__django-11551](django__django-11551.md) - admin check precedence can be wrong for same-name field/admin attributes.
3. [django__django-11555](django__django-11555.md) - related-ordering expression resolution can fail on a narrow child shape.
4. [django__django-11728](django__django-11728.md) - admindocs regex simplification can mishandle multiple or nested groups.
5. [django__django-13012](django__django-13012.md) - deprecated custom expression signatures can break through `ExpressionWrapper`.
6. [django__django-13028](django__django-13028.md) - non-expression RHS values can be walked as expression containers.
7. [django__django-14122](django__django-14122.md) - `QuerySet.ordered` can use a weaker grouped-query sentinel.
8. [django__django-14170](django__django-14170.md) - ISO-year lookup can crash at the maximum-year boundary.
9. [django__django-14725](django__django-14725.md) - edit-only formsets can still create records through a semi-private override.
10. [django__django-15127](django__django-15127.md) - stale direct references to `LEVEL_TAGS` can survive settings changes.
11. [django__django-15268](django__django-15268.md) - migration reducer ordering can bypass inherited reductions.
12. [django__django-16315](django__django-16315.md) - upsert field-name resolution can broaden backend hook effects.
13. [django__django-16819](django__django-16819.md) - index add/rename/remove migration composition can remain unreduced.
14. [django__django-17087](django__django-17087.md) - migration serialization can emit invalid paths for local class-bound methods.
15. [matplotlib__matplotlib-25311](matplotlib__matplotlib-25311.md) - draggable pickling has legacy/manual canvas-state edges.
16. [matplotlib__matplotlib-25775](matplotlib__matplotlib-25775.md) - Cairo path-effect text can ignore copied antialiasing.
17. [psf__requests-2931](psf__requests-2931.md) - shared bytes encoder still has a latent raw-bytes hazard.
18. [pylint-dev__pylint-6386](pylint-dev__pylint-6386.md) - `-v` can be consumed after `--`.
19. [scikit-learn__scikit-learn-11310](scikit-learn__scikit-learn-11310.md) - deprecated `grid_search` lacks the same `refit_time_` behavior.
20. [scikit-learn__scikit-learn-13496](scikit-learn__scikit-learn-13496.md) - positional constructor arguments can be silently shifted for 6+-positional calls.
21. [scikit-learn__scikit-learn-26323](scikit-learn__scikit-learn-26323.md) - `_safe_set_output(transform=None)` can raise on unconfigurable children.
22. [sphinx-doc__sphinx-7440](sphinx-doc__sphinx-7440.md) - `:term:` pending-reference target shape can regress.
23. [sphinx-doc__sphinx-7910](sphinx-doc__sphinx-7910.md) - Napoleon owner detection has class-decorator and globals-fallback edges.
24. [sphinx-doc__sphinx-8593](sphinx-doc__sphinx-8593.md) - attribute-comment metadata precedence can be wrong in conflicts.
25. [sphinx-doc__sphinx-9229](sphinx-doc__sphinx-9229.md) - class-alias source-comment dependency tracking can be missing.
26. [sphinx-doc__sphinx-9367](sphinx-doc__sphinx-9367.md) - one-element tuple subscript syntax can be rendered as a different operation.
27. [sympy__sympy-13877](sympy__sympy-13877.md) - determinant input `S.NaN` needs an explicit boundary.
28. [sympy__sympy-17139](sympy__sympy-17139.md) - `_TR56(pow=True)` has a narrow exponent-domain gap.
29. [sympy__sympy-21847](sympy__sympy-21847.md) - empty-variable monomial generation can yield `1` despite positive `min_degree`.
30. [sympy__sympy-24066](sympy__sympy-24066.md) - units dimension equivalence can leak low-level `TypeError`.
