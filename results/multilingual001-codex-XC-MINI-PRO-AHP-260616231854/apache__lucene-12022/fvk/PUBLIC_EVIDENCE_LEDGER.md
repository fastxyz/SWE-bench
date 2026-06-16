# Public Evidence Ledger

Status: constructed from allowed public inputs.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "When performing a search using a shape geometry query of relation type `QueryRelation.CONTAINS`, it is possible to get a false positive..." | The repair target is indexed shape geometry `CONTAINS` behavior. | Encoded in SPEC and proof obligations. |
| E2 | `benchmark/PROBLEM.md` | "one of its triangles is simplified to a single line segment" | The target branch is degenerate decoded triangle-to-line simplification. | Encoded in SPEC and K claims. |
| E3 | `benchmark/PROBLEM.md` | "records whether it is part of the external polygon by taking that knowledge from first line segment of the triangle, not necessarily the part of the triangle being retained" | The line's externally-visible edge flag must come from the retained segment, not unconditionally from original `ab`. | Encoded in PO-1 and claim `RESOLVE-AEQB-LINE`. |
| E4 | `benchmark/PROBLEM.md` | "The simplification code should instead take this knowledge from a line segment that is not being collapsed" | When `A-B` collapses, the retained non-collapsed segment is `B-C`, so `ab` must become old `bc`. | Encoded in PO-1 and V1 confirmation. |
| E5 | `LatLonShapeQuery` / `XYShapeQuery` source | The `LINE` case calls `component2D.withinLine(..., scratchTriangle.ab, ...)`. | `ab` is the edge flag that determines `CONTAINS` line handling for decoded lines. | Encoded in PO-4. |
| E6 | `ShapeField.DecodedTriangle.TYPE` comment | `LINE` means "first and third coordinates are equal." | The canonical line representation is `A-B-A`; the line flag read by queries is `ab`. | Encoded in SPEC and K claims. |
| E7 | Current V1 source | In the `A == B`, `C` distinct branch, `triangle.ab = triangle.bc` precedes coordinate rewriting. | Candidate implementation matches E3-E5 for the reported branch. | Verified by constructed proof. |
| E8 | User task | "Do not modify any test files" and "do not attempt to run tests, Python, or K framework tooling." | Verification is static; commands appear only as artifacts. | Reflected in PROOF and notes. |
