# Spec Audit

Status: constructed, not machine-checked.

| Formal Claim | Intent Entry | Audit | Notes |
|---|---|---|---|
| C-EMPTY | Intent item 1 | Pass | Empty selected input has no holders to expand. |
| C-SINGLE-CLIP | E-001, E-004, E-005 | Pass | Endpoint clipping directly expresses the issue's missing start/end adjustment. |
| C-MULTI-CLIP | Intent item 1, E-007 | Pass | Existing lookup behavior clips only the boundary holders; middle selected holders already lie within the query span under the selected-list invariant. |
| C-ZERO-INTERIOR | E-001, E-002, E-005 | Pass | This is the reported failure family: zero-length query inside an adjusted holder must return a zero-length holder interval. |
| C-FRAME | E-007 | Pass | The issue concerns interval bounds only, not payload replacement or selection order. |
| C-COMPAT | E-008 | Pass | V1 changes no public signatures or return types. |

No claim relies on the legacy `queryInterval.overlaps(holderInterval)` clipping guard as intended behavior. That legacy behavior is marked suspect because the public issue identifies it as the cause of the defect.
