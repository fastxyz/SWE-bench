# Public Compatibility Audit

Status: static source audit.

## Changed symbol

`org.apache.lucene.document.ShapeField.resolveTriangleType(DecodedTriangle triangle)`

- Visibility: package-private static helper.
- Signature: unchanged.
- Callers: `ShapeField.decodeTriangle`.
- Public behavior affected: decoded line metadata in `DecodedTriangle.ab` after `decodeTriangle`.
- Compatibility status: compatible. The change corrects metadata for the retained line segment without changing method signatures, field names, enum values, query APIs, or binary field encoding size.

## Public query callsites inspected

- `LatLonShapeQuery` `LINE` `CONTAINS` path calls `component2D.withinLine(..., scratchTriangle.ab, ...)`.
- `XYShapeQuery` `LINE` `CONTAINS` path calls `component2D.withinLine(..., scratchTriangle.ab, ...)`.
- `LatLonShapeBoundingBoxQuery` has the same decoded line metadata dependency for bounding-box contains.

## Test files

No test files were modified.

## Unhandled compatibility items

None found in the allowed source inspection.
