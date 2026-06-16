# FVK Notes

## Decision Summary

V1 is kept unchanged. The FVK audit confirmed that the endpoint-only clipping change discharges the public issue obligation without requiring another production edit.

## Trace To Findings And Proof Obligations

- Keep the source change in `VersionedIntervalTimeline.lookup`: justified by F-001 and PO-003 through PO-005. The pre-fix path can leave a selected zero-length query holder as `[T,HE]`; V1 first clips start to `T` and then clips end to `T`.
- Do not add an early empty-list return for all zero-length queries: rejected by the same PO-005 reasoning. The timeline layer can return a selected holder clipped to `[T,T]`, which satisfies the "matches nothing" query intent without changing lookup's broader selection semantics.
- Do not edit payload handling or holder construction: F-002 and PO-006 confirm V1 preserves true interval, version, object, count, and order.
- Do not edit other searched `overlaps` callsites: F-004 and PO-007 found no additional positive-range expansion pattern tied to the public issue.
- Do not modify tests or claim machine-checked proof: F-003 records that this session cannot run tests or K tooling, so proof and test-redundancy conclusions remain constructed only.

## Source Changes In This FVK Phase

No source files were changed during the FVK phase. The existing V1 production edit remains the complete fix according to the constructed spec and proof obligations.
