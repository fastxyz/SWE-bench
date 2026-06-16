# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue intent, source
inspection, and proof construction only.

## F-1: V1 Addresses the Reported Component-Predicate False Negative

Trace: PO-1, PO-2, PO-4.

Input: the issue's polygon with min bounds at `decode(Integer.MAX_VALUE - 3)`, max bounds at
`decode(Integer.MAX_VALUE)`, and a point input at `decode(Integer.MAX_VALUE - 2)` on both latitude
and longitude axes.

Observed in pre-fix code: `createSubBoxes` used a single raw re-encode of the double query bounds.
If floating round-trip arithmetic shifted the lower bound upward or upper bound downward by one
encoded cell, the component predicate could reject the point before exact `tree.contains` ran.

Expected: the point is inside the polygon and the doc-values polygon query should count it.

V1 status: resolved. Conservative lower and upper helpers make the grid include every encoded cell
whose decoded coordinate lies on the query boundary or inside the query interval.

## F-2: V1 Preserves False-Positive Filtering

Trace: PO-3.

Input: any extra encoded cell admitted only because conservative bounds expanded the grid.

Observed risk: expanding a grid can introduce false positives if newly admitted cells are accepted
without exact or relation checks.

Expected: extra cells must be filtered by `Component2D.relate` and exact `tree.contains` for
crossing cells.

V1 status: resolved. The patch changes only grid bounds. It leaves the existing relation table and
the `CELL_CROSSES_QUERY` exact-check path unchanged.

## F-3: No Public Compatibility Regression Found

Trace: PO-6.

Input: public callers of `GeoEncodingUtils`, `LatLonDocValuesField`, and `LatLonDocValuesQuery`.

Observed: V1 adds private helper methods and changes only private grid-bound calculations inside
`createSubBoxes`.

Expected: no public API, field encoding, query relation, or test file changes.

V1 status: resolved. No source edits beyond `GeoEncodingUtils.java` are required.

## F-4: Constructed Proof Depends on Existing Component2D Relation Soundness

Trace: PO-3, proof capability boundary in PO-6.

Input: a component implementation whose `relate` returns `CELL_OUTSIDE_QUERY` for a rectangle that
contains a point accepted by `contains`.

Observed risk: such an implementation would violate the relation contract and could still create a
false negative after V1.

Expected: `Component2D.relate` is sound with respect to `contains` for the decoded rectangle passed
by the grid.

Status: proof boundary, not a V1 code bug. The public issue localizes the failure to predicate grid
rejection; V1 fixes that mechanism while relying on the existing `Component2D` relation contract.

## F-5: No Additional Source Change Justified

Trace: F-1, F-2, F-3, PO-1 through PO-6.

Alternative considered: bypass `Component2DPredicate` in `LatLonDocValuesQuery` and call
`component2D.contains` directly for every point.

Outcome: rejected. It would fix the doc-values symptom but leave the shared component predicate
able to reject valid encoded boundary cells. The intent evidence points to the predicate itself,
and PO-2 is discharged by the V1 shared helper change.
