# Intent Spec

Status: constructed from public workspace evidence, not machine-checked.

## Required Behavior

1. For shape geometry queries with relation `QueryRelation.CONTAINS`, an indexed polygon triangle that simplifies to a line must keep the edge-from-polygon metadata for the line segment that survives simplification.

2. If the first decoded edge `A-B` collapses because `A` and `B` are the same encoded point but `C` is distinct, the surviving line is represented as `A-C-A`. The metadata consumed by `withinLine` is `ab`, so `ab` must be copied from the non-collapsed `B-C` edge, not from the collapsed `A-B` edge.

3. If a decoded triangle simplifies through `A == C` or `B == C`, the canonical line segment observed by `withinLine` is still `A-B`, so `ab` remains the metadata for a non-collapsed represented segment.

4. Point and non-degenerate triangle classification must be preserved: all three equal points become `POINT`; three distinct decoded points remain `TRIANGLE`.

5. The fix must not change public method signatures, query dispatch, tessellation APIs, or test files.

## Out Of Scope For This Issue

Shape doc-values geometry queries are not implemented in the inspected code path, and the public issue describes indexed shape geometry search behavior. Doc-values metadata irregularities are therefore not used as a repair obligation for this task.
