# Spec Audit

| Claim | Intent coverage | Result | Notes |
| --- | --- | --- | --- |
| SPEC-C0 | E3, E6 | Pass as diagnostic | It models the reported pre-fix failure mechanism: same-column unique and index objects both selected by `index=True`. |
| SPEC-C1 | E1, E2, E3, E4, E5, E6 | Pass | It proves V1 selects only `_idx` when `_uniq` appears before it. |
| SPEC-C2 | E1, E2, E3, E4, E5, E6 | Pass | It proves V1 selects only `_idx` when `_idx` appears before `_uniq`, avoiding an implementation-derived order assumption. |
| Frame: unique deletion | E4, E8 | Pass | Source still uses `{'unique': True}` for `alter_unique_together()`. |
| Compatibility | E8 | Pass | No public signature, override contract, or operation serialization shape changed. |
| No physical index recreation when moving to `Meta.indexes` | E7 | Ambiguous/unresolved | Public issue names the concern, but source evidence shows named `Index` state makes a no-op database migration nontrivial. Kept as F2/PO5 rather than silently declared fixed. |
