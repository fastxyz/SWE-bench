# Spec Audit

Status: pass, constructed but not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| `VIEW-OR-CHANGE-CAN-VIEW` | I2, E1, E6 | Pass | View-only users retain read access. Change implies view, matching Django's base `has_view_permission()` pattern. |
| `WRITE-FOLLOWS-TARGET-CHANGE` | I1, I3, E4, E5 | Pass | This is the key V1 correction: write does not follow view. |
| `VIEW-ONLY-WRITE-FALSE` | I1, E1, E3 | Pass | Directly captures the reported failing case. |
| `VIEW-ONLY-POST-PRESERVES` | I1, E1, E3, E4 | Pass | Captures the save-path consequence: submitted add/remove data must not change the relation. |
| `TARGET-CHANGE-POST-APPLIES` | I3, E5 | Pass | Preserves existing behavior where target `change` grants relationship inline editing. |
| `TARGET-CHANGE-WRITE-TRUE` | I3, E5 | Pass | Existing public tests support this positive case. |

## Ambiguities

No unresolved ambiguity blocks V1 for the reported issue.

The audit considered adding a parent model `change` permission requirement for auto-created m2m relationship writes. That would be a broader behavior change because Django admin already has a concept of editable inlines contributing save capability independently of parent form editability. The public issue only establishes that view-only users with no write permission should not edit the m2m relation. Existing m2m inline tests also focus the write gate on target model `change`. Therefore the parent-change gate is not part of this spec.
