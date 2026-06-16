# FVK Notes

## Decision

V1 stands unchanged. No additional source files were edited during the FVK pass.

## Trace to FVK findings and proof obligations

`fvk/FINDINGS.md` F-1 confirms that V1 fixes the reported mechanism: when decoded vertices `A` and `B` collapse but `C` is distinct, `resolveTriangleType` now copies old `bc` into result `ab`. This discharges `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-4, because `ab` is the field passed to `withinLine` by the `CONTAINS` query line path.

F-2 explains why the other degenerate line branches do not need a further source change. In the `A == C` and `B == C` cases, the canonical represented line segment observed by query code is `A-B`, so old `ab` is already the relevant non-collapsed segment flag. That discharges PO-2.

PO-3 and PO-5 required preserving point and non-degenerate triangle classification and avoiding public API or test changes. V1 changes only the `A == B`, `C` distinct metadata assignment in `ShapeField.resolveTriangleType`, so those frame obligations remain satisfied.

F-3 and PO-6 record the verification boundary: the proof artifacts and K commands were constructed but not executed, as required by the task. This did not block applying or keeping the fix, but it does mean no test-removal recommendation is made.

## Alternatives considered

Changing `Tessellator` was rejected because the proof localizes the defect to decoded line simplification: the tessellator already supplies per-edge metadata, while the failing path is the loss of the retained edge's metadata when coordinates are canonicalized to a line.

Changing shape doc-values code was rejected because the public issue and PO-4 target indexed shape geometry `CONTAINS` queries. The inspected shape doc-values geometry query entry point is not implemented, so doc-values metadata is outside this repair obligation.

Updating additional line flags beyond `ab` was not required for this issue because both the public failure mechanism and query bridge consume only `ab` for decoded `LINE` values. The FVK spec therefore keeps the proof property-complete for the reported defect without adding unrelated behavioral change.
