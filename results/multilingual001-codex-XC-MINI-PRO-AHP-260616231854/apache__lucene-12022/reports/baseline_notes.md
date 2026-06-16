# Baseline Notes

## Root cause

`ShapeField.decodeTriangle` calls `resolveTriangleType` to simplify degenerate encoded triangles into points or lines. When vertices `A` and `B` decode to the same coordinate while `C` remains distinct, `resolveTriangleType` rewrites the triangle into the canonical line form `A-C-A`, but it left `triangle.ab` unchanged. Later `CONTAINS` shape queries pass only `scratchTriangle.ab` into `Component2D.withinLine`, so the line inherited the edge provenance from the collapsed `A-B` segment instead of the surviving `B-C` segment. If `A-B` was an internal triangle edge and `B-C` was an outer polygon edge, the query could miss the outer-edge intersection and produce a false positive contains result.

## Changed files

`repo/lucene/core/src/java/org/apache/lucene/document/ShapeField.java`

Updated `resolveTriangleType` so the `A == B` degenerate-triangle case copies `triangle.bc` into `triangle.ab` before rewriting coordinates to the canonical line representation. This preserves the edge-from-polygon metadata for the line segment that remains after simplification and keeps the downstream `withinLine` call using the correct outer-edge flag.

## Assumptions and alternatives considered

I assumed the issue concerns indexed shape queries, where `ShapeField.decodeTriangle` is used by `LatLonShapeQuery`, `XYShapeQuery`, and the bounding-box query path before calling `withinLine`.

I considered changing tessellation edge provenance in `Tessellator`, but the tessellator already tracks edge flags per triangle edge; the bug appears when a decoded triangle is simplified and the edge flag is not moved with the surviving segment.

I considered changing all degenerate cases, but when `A == C` or `B == C`, the canonical line representation already uses `A-B`, so `triangle.ab` corresponds to a non-collapsed retained segment. The targeted bug is the `A == B` case, where the first edge is the collapsed segment.

I also noticed the polygon doc-values construction paths set the second edge flag from `isEdgefromPolygon(0)`, but shape doc-values geometry queries are not implemented in this code path and the reported issue is about shape geometry search queries, so I left that unrelated behavior unchanged.

No tests or project code were run, per the task constraints.
