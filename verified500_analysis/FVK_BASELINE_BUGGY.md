# FVK Baseline-Buggy Confirmed Cases

This document keeps only the confirmed cases where the baseline arm passed the
official tests but still had a concrete bug, and the FVK arm fixed it. These
are the cases suitable for citing as "baseline succeeded but was still wrong;
FVK found and corrected the problem."

1. `pydata__xarray-4094`

   Baseline bug: `DataArray.to_unstacked_dataset()` used unconstrained
   `squeeze(drop=True)` when reconstructing variables.

   Concrete failure: a stack-then-unstack round trip can delete a legitimate
   sample dimension when that dimension has length 1, turning a one-dimensional
   variable into a scalar.

   FVK formal argument: sample dimensions are frame conditions. Only dimensions
   proven to be consumed stacked metadata or missing-level sentinels may be
   squeezed.

   Why confirmed: execution-backed analysis found a real test-outside failure;
   FVK also improves on the official human fix for this edge case.

2. `sphinx-doc__sphinx-9367`

   Baseline bug: one-element tuple subscripts were rendered without the
   trailing comma.

   Concrete failure: `obj[1,]` was emitted as `obj[1]`. Those are different
   Python operations because the first uses a tuple key and the second uses a
   scalar key.

   FVK formal argument: tuple cardinality must be preserved on every unparse
   path. The trailing comma is the proof witness for a one-element tuple.

   Why confirmed: execution-backed analysis showed baseline and the official
   fix missed the subscript path; FVK corrected it.

3. `django__django-13121`

   Baseline bug: nested temporal subtraction in duration arithmetic still
   routed through interval/date formatting on non-native duration backends.

   Concrete failure: an expression such as `DurationField + (end - start)` can
   crash on SQLite/MySQL instead of returning the expected `timedelta`.

   FVK formal argument: same-type temporal subtraction is duration-producing.
   Once both operands are durations, arithmetic must use numeric microsecond
   operations.

   Why confirmed: execution-backed analysis found the nested-subtraction crash
   in the baseline and official fix; FVK returned the correct value.

4. `django__django-14170`

   Baseline bug: ISO-year lookup bounds used `value + 1` unconditionally.

   Concrete failure: filtering with `field__iso_year=9999` tries to construct
   ISO year 10000 and raises `ValueError`.

   FVK formal argument: `datetime.MAXYEAR` is an explicit boundary case. The
   upper bound for year 9999 must use `date.max` or `datetime.max`, not
   `fromisocalendar(value + 1, ...)`.

   Why confirmed: execution-backed analysis showed baseline and the official
   fix crash on the maximum-year lookup; FVK guards the boundary.

5. `sympy__sympy-14531`

   Baseline bug: the reported printer paths were fixed, but sibling printers
   still interpolated nested operands with raw string formatting.

   Concrete failure: with `sympy_integers=True`, objects such as intervals or
   lambdas could still print rationals as raw `1/2` forms instead of exact
   `S(1)/2` forms.

   FVK formal argument: composite printers must render nested SymPy operands
   through `self._print(...)` so active printer options are preserved
   recursively.

   Why confirmed: execution-backed analysis found multiple sibling printer
   paths still wrong in baseline; FVK fixed the broader family.

6. `sympy__sympy-24066`

   Baseline bug: dimension equivalence helpers were called inline and could
   leak low-level `TypeError` for unsupported symbolic dimensions.

   Concrete failure: an addition involving unsupported dimension expressions can
   raise `TypeError` instead of the expected incompatible-dimension error.

   FVK formal argument: unsupported dimensional analysis is a conservative
   negative result. Helper failure must not escape as the public error mode.

   Why confirmed: execution-backed analysis found the baseline exception leak;
   FVK restored the expected public error behavior.

7. `django__django-11206`

   Baseline bug: decimal formatting handled tiny nonzero values but missed
   zero-valued `Decimal` objects with large stored exponents.

   Concrete failure: `Decimal("0E+200")` with fixed decimal places can render
   malformed scientific notation such as `0.00e+200`.

   FVK formal argument: zero is exactly representable at every fixed decimal
   width. It must be handled before nonzero adjusted-exponent thresholds.

   Why confirmed: execution-backed analysis showed baseline emits malformed
   zero formatting; FVK emits fixed-width zero.

8. `django__django-13569`

   Baseline bug: GROUP BY pruning kept some order-by expressions but dropped
   correlated subqueries with external columns.

   Concrete failure: an aggregate query ordered by a correlated `Subquery` can
   drop a semantically required grouping expression, producing wrong SQL or a
   backend error.

   FVK formal argument: any grouping expression whose flattened sources expose
   non-empty `get_external_cols()` must be retained.

   Why confirmed: execution-backed analysis found the correlated-subquery GROUP
   BY gap in baseline; FVK retained the required grouping expression.

9. `django__django-14725`

   Baseline bug: the edit-only guard lived only in `save_new_objects()`.

   Concrete failure: a formset subclass overriding `save_new_objects()` without
   calling `super()` can still create new objects even when `edit_only=True`.

   FVK formal argument: the public `save()` entry point itself must avoid
   dispatching to new-object creation when edit-only mode is active.

   Why confirmed: execution-backed analysis demonstrated the bypass; FVK moved
   the protection to the public save path.

10. `matplotlib__matplotlib-25960`

    Baseline bug: subfigure spacing was read from generic user-created
    `GridSpec` objects.

    Concrete failure: subplot spacing configured for a normal `GridSpec` can
    leak into `add_subfigure()` placement and move subfigures incorrectly.

    FVK formal argument: only GridSpecs created by `Figure.subfigures()` carry
    subfigure spacing metadata.

    Why confirmed: execution-backed analysis found the spacing leak; FVK scoped
    the metadata source correctly.

11. `scikit-learn__scikit-learn-13496`

    Baseline bug: `warm_start` was inserted in the middle of the constructor
    signature.

    Concrete failure: old positional callers silently bind later arguments to
    the wrong parameters after the new argument is inserted.

    FVK formal argument: adding an optional parameter is a public-call
    compatibility obligation. Existing positional slots must keep their
    meanings.

    Why confirmed: execution-backed analysis showed positional-call breakage;
    FVK appends the parameter instead of shifting existing slots.

12. `astropy__astropy-14096`

    Baseline bug: the descriptor-provider search stopped too early in the MRO.

    Concrete failure: mixin or subclass properties after `SkyCoord` in the MRO
    can be missed, causing Astropy to report the wrong attribute error.

    FVK formal argument: descriptor lookup must scan the full MRO and preserve
    the inner property error from the first real provider.

    Why confirmed: execution-backed analysis showed the truncated MRO scan masks
    the real property failure; FVK scans the full provider chain.

13. `psf__requests-2931`

    Baseline bug: the caller path was patched, but shared `_encode_params()`
    still decoded raw bytes as ASCII.

    Concrete failure: direct or shared use of `_encode_params(non_ascii_bytes)`
    can still fail or alter bytes that should be preserved.

    FVK formal argument: for every byte sequence `B`, `_encode_params(B)` must
    return `B` unchanged.

    Why confirmed: execution-backed analysis found the shared encoder hazard;
    FVK fixed the root helper rather than only one caller.

14. `django__django-11095`

    Baseline bug: `to_field_allowed()` called dynamic `get_inlines(request)`
    without an object context.

    Concrete failure: object-dependent inline hooks can return no inlines for
    `obj=None`, causing valid inline models to be omitted from related-object
    validation in public admin raw-id / `to_field` paths.

    FVK formal argument: related-object validation is a static admin
    registration obligation. It must inspect `admin.inlines`, not an objectless
    dynamic hook result.

    Why confirmed: gold comparison shows the official fix does not touch
    `to_field_allowed()`; the baseline introduced the regression and FVK
    reverted that path to the correct static behavior.

15. `pydata__xarray-4695`

    Baseline bug: the `.loc` keyword-collision fix missed internal dynamic
    selection helpers that still used `.sel(**{dim: value})`.

    Concrete failure: dimensions named like reserved `.sel()` parameters, such
    as `method`, can still be misinterpreted outside the direct `.loc` path.

    FVK formal argument: dynamically derived dimension names must be passed as
    mapping indexers, not unpacked as keyword parameters.

    Why confirmed: gold comparison shows the official fix only covered the
    direct `.loc` path; FVK fixed the same root collision in additional public
    API paths.

16. `sphinx-doc__sphinx-9229`

    Baseline bug: class-alias source comments were used without recording the
    source dependency.

    Concrete failure: incremental rebuilds can miss changes to the source file
    that supplied alias documentation.

    FVK formal argument: every source-comment docstring used for alias
    documentation must record the analyzer source as a rebuild dependency.

    Why confirmed: gold comparison uses a different implementation path, while
    FVK's dependency recording fixes a real incremental-build bug in the
    baseline implementation.
