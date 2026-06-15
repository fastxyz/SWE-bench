# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict | Notes |
| --- | --- | --- | --- |
| CLAIM-EXPRESSION-BYPASSES-GET-ORDER-DIR | I1, I2, E1-E3 | Pass | Directly addresses the reported `OrderBy`/`Lower` subscript crash. |
| CLAIM-F-LEAF-USES-RELATED-CONTEXT | I4, E8 | Pass | Required so `Lower('name')` and `OrderBy(F('name'))` on a related model do not resolve from the root model. |
| CLAIM-NON-ORDERBY-ASC-WRAP | I3, E3, E5 | Pass | Mirrors top-level `get_order_by()` behavior for non-`OrderBy` expressions. |
| CLAIM-DESC-REVERSAL | I3, E5 | Pass | Preserves relation ordering reversal semantics. |
| CLAIM-STRING-FRAME | I5 | Pass | Confirms the fix does not route strings away from the old string path. |
| CLAIM-NON-SOURCE-CHILD-FRAME | I7, E9 | Pass for safety, incomplete for full expression semantics | Prevents a V1 helper crash on non-expression child nodes. It does not prove alias-relative semantics for `Q` lookup strings. |

## Adequacy Result

The claims are adequate for the reported public issue family: expression items
that are `OrderBy`, `F`, or transforms/functions containing plain `F()` leaves.

The claims are intentionally not a proof of every possible Django expression
inside related model `Meta.ordering`. Conditional `Case/When(Q(...))` ordering
is marked as residual risk in `fvk/FINDINGS.md` rather than being treated as
proved by this audit.
