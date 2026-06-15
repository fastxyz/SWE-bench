# PROOF_OBLIGATIONS

Status: all obligations discharged by inspection and constructed proof; not machine-checked.

## PO1 - View access stays read access

- Statement: For auto-created m2m intermediary inlines, target `view` or target `change` permission is sufficient for `has_view_permission()`.
- Evidence: issue concerns view permissions and does not require hiding readable relationships.
- Code: `InlineModelAdmin.has_view_permission()` calls `_has_any_perms_for_target_model(request, ['view', 'change'])`.
- Formal claim: `VIEW-OR-CHANGE-CAN-VIEW`.
- Result: discharged.

## PO2 - Relationship write access does not follow view permission

- Statement: For auto-created m2m intermediary inlines, `has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` must be false when target `change` permission is false, even if target `view` permission is true.
- Evidence: public issue's view-only user must not add/remove relationships.
- Code: all three write hooks call `_has_any_perms_for_target_model(request, ['change'])`.
- Formal claims: `WRITE-FOLLOWS-TARGET-CHANGE`, `VIEW-ONLY-WRITE-FALSE`.
- Result: discharged.

## PO3 - View-only inline rendering is read-only

- Statement: If the auto-created m2m inline has view permission but no write permissions, initial forms are rendered as read-only, no empty add form is yielded, and deletion UI is unavailable.
- Evidence: Django admin helper uses the permission booleans passed by `get_inline_formsets()`.
- Code: `get_inline_formsets()` passes `has_add_permission`, `has_change_permission`, `has_delete_permission`, and `has_view_permission`; `InlineAdminFormSet.__iter__()` treats fields as read-only when `has_change_permission` is false and yields the empty form only when `has_add_permission` is true.
- Formal claim: represented by the false-write side of `VIEW-ONLY-POST-PRESERVES`.
- Result: discharged by source inspection.

## PO4 - View-only POST preserves the relationship

- Statement: If target `change` permission is false, submitted inline POST data must not add, remove, or replace m2m relationships.
- Evidence: public issue says view-only submitted edits should not be accepted.
- Code: `_create_formsets()` bypasses validation for view-only initial forms unless `has_delete_permission()` is true; `InlineModelAdmin.get_formset()` wraps `has_changed()` so unauthorized existing and new forms report unchanged; `can_delete` is false without delete permission.
- Formal claim: `VIEW-ONLY-POST-PRESERVES`.
- Result: discharged.

## PO5 - Target change still permits m2m relationship editing

- Statement: The fix must not break existing behavior where target model `change` permission permits add/change/delete of auto-created m2m relationship rows.
- Evidence: public tests for #8060 document this behavior.
- Code: all auto-created m2m write hooks return true when target `change` permission is present.
- Formal claims: `TARGET-CHANGE-WRITE-TRUE`, `TARGET-CHANGE-POST-APPLIES`.
- Result: discharged.

## PO6 - Public API compatibility

- Statement: The fix must not change public hook signatures or break subclass overrides.
- Evidence: admin docs define the hook signatures.
- Code: V1 changes only method bodies and adds private helpers. Public callsites use the same arguments.
- Formal artifact: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Result: discharged.

## PO7 - Adequacy and honesty gate

- Statement: The formal claims must match the intent spec, and proof status must be labeled honestly.
- Evidence: FVK docs require intent-first specification, formal English paraphrase, audit, and "constructed, not machine-checked" labeling.
- Artifacts: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-admin-permissions.k`, `admin-inline-permissions-spec.k`, and `PROOF.md`.
- Result: discharged as constructed, not machine-checked.
