# FVK Findings

Status: constructed, not machine-checked.  Findings are based on public intent
and source inspection only.

## F-001: Boolean line contour default selected the numeric locator path

Input: `plt.contour(boolean_2d_array)` with no `levels`.

Observed before the fix: the original code converted `Z` to `float64`, so
boolean data became ordinary numeric `0.0`/`1.0` data before level selection.
The normal automatic locator could then produce multiple levels such as those
shown in the issue.

Expected: the default level set is `[0.5]`.

Status: resolved by PO-1 and PO-2.  V1 captured the bool dtype before the
float conversion and selected `[0.5]` for the plain boolean line-contour
default.  The FVK audit keeps this behavior.

## F-002: Boolean filled contours need interval boundaries, not one line level

Input: `plt.contourf(boolean_2d_array)` with no `levels`.

Observed before the fix: the same automatic path was used, and the public hint
notes that one level is invalid for filled contours.

Expected: the natural filled-contour boundaries are `[0, 0.5, 1]`.

Status: resolved by PO-3.  V1 selected three increasing levels for default
boolean `contourf`, satisfying the filled-contour length check.

## F-003: Single-valued boolean arrays must still keep the semantic default

Input: `plt.contour(all_false_bool_array)` or `plt.contour(all_true_bool_array)`
with no `levels`.

Potential issue: Matplotlib's existing line-contour fallback replaces a level
set with `[zmin]` when no level lies strictly inside the data range.

Expected: the boolean default remains `[0.5]`; it simply produces no boundary
segments when the field has no True/False boundary.

Status: resolved by PO-4.  V1 set `auto_bool_levels` and skipped the legacy
inside-range fallback for this path.

## F-004: Caller-directed level choices should not be overwritten

Input: boolean `Z` with explicit positional levels, keyword `levels`, an
integer level count, an explicit locator, or log-scale contouring.

Expected: these are caller-directed or non-default level choices and should
follow the existing behavior.

Status: confirmed by PO-5.  V1 only applies the boolean defaults when no levels
argument is present, `self.levels is None`, `self.locator is None`, and the
contour is not log-scale.

## F-005: Public docs did not state the new boolean default

Input: a user reading the public `levels` docstring after the behavior change.

Observed in V1: the implementation changed the automatic default, but the
docstring still only described explicit integer and array-like `levels`.

Expected: the public documentation states the boolean defaults.

Status: resolved in V2 by PO-7.  The `levels` docstring now states `[0.5]` for
`.contour` and `[0, 0.5, 1]` for `.contourf`.

## F-006: Triangular contours are outside this issue's proven scope

Input: `tricontour` or `tricontourf` with boolean `z`.

Expected from this issue: no required change.  The issue describes 2D boolean
arrays passed to `contour()` and shows the regular image-like grid path.

Status: no code change.  This is a scope boundary, not a code bug.  A future
issue could ask for the same policy in triangular contours.

## F-007: Proof and tests remain unexecuted by constraint

Input: the constructed K commands and the Matplotlib test suite.

Observed: this task forbids running tests, Python, or K tooling.

Expected: artifacts must state that proof obligations are constructed but not
machine-checked, and no test-removal recommendation is actionable until the
commands are run in a real execution environment.

Status: open honesty caveat, not a code defect.
