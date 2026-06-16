# FVK Spec

Status: constructed, not machine-checked.

## Scope

The verified unit is `ShapeField.resolveTriangleType(DecodedTriangle triangle)` as reached through `ShapeField.decodeTriangle` before `LatLonShapeQuery`, `XYShapeQuery`, and `LatLonShapeBoundingBoxQuery` evaluate `QueryRelation.CONTAINS` line cases.

The proof focuses on the observable defect axis from the public issue: for a decoded degenerate triangle that becomes a `TYPE.LINE`, the `ab` flag passed to `Component2D.withinLine` must describe the retained line segment's membership in the original polygon boundary.

## Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. Critical entries:

- E2: The bug occurs when a triangle is simplified to a line segment.
- E3: The line currently takes external-polygon knowledge from the first triangle segment, which may not be retained.
- E4: The simplification must take this knowledge from a segment that is not collapsed.
- E5: `CONTAINS` line queries consume `scratchTriangle.ab`.

## Contract

Let an input decoded triangle have vertices `A=(aX,aY)`, `B=(bX,bY)`, and `C=(cX,cY)`, edge flags `ab`, `bc`, and `ca`, and any prior `type`.

1. If `A == B == C`, the result is `POINT`.
2. If `A == B` and `C` is distinct, the result is a canonical `LINE` with coordinates `A-C-A`, and result `ab == old bc`.
3. If `A == C` and `A` is distinct from `B`, the result is `LINE` with existing `A-B-A` coordinates, and result `ab == old ab`.
4. If `B == C`, after the previous cases are excluded, the result is a canonical `LINE` with coordinates `A-B-A`, and result `ab == old ab`.
5. If the three points are pairwise distinct, the result is `TRIANGLE`.

The central postcondition is item 2. It ensures the edge flag read by `withinLine` comes from `B-C`, which is not collapsed in that branch.

## Frame Conditions

- No public signatures or field layouts change.
- `decodeTriangle` continues to canonicalize point and line coordinates as before.
- Non-degenerate triangles keep all coordinates and flags.
- The patch does not alter tessellation or query algorithms.

## Formal Artifacts

- `mini-java-shapefield.k`: minimal K fragment for the mutable decoded-triangle state and `resolveTriangleType`.
- `shape-field-spec.k`: reachability claims for all `resolveTriangleType` classification branches.
