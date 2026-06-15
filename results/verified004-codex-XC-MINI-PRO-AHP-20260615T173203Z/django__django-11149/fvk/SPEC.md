# SPEC

Status: constructed for FVK audit, not machine-checked.

## Scope

This FVK pass specifies the permission and save-preservation behavior for `InlineModelAdmin` when `self.opts.auto_created` is true because the inline model is an auto-created many-to-many intermediary model such as `Report.photos.through`.

The full Django admin stack is not modeled. The mini semantics keeps only the property-bearing axis for this issue:

- whether the target model grants `view` permission;
- whether the target model grants `change` permission;
- whether the inline POST is accepted as the new relationship state or ignored.

This abstraction distinguishes the failing legacy behavior from the fixed behavior. A failing instance maps target-view-only users to `write_allowed = true` and accepts the submitted relationship state. A passing instance maps target-view-only users to `write_allowed = false` and preserves the original relationship state.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

- E1/E3: view-only users must not be able to add or remove m2m relationships through the inline.
- E2/E6: the relevant path is the auto-created intermediary model path.
- E4: add/change/delete permission hooks decide whether inline writes are permitted.
- E5: target model `change` permission is the established write gate for auto-created m2m through inlines.

## Formal Contract

Let:

- `target_view` mean the target model's view permission is present;
- `target_change` mean the target model's change permission is present;
- `original_rel` mean the relationship state before the admin POST;
- `submitted_rel` mean the relationship state represented by submitted inline formset data.

The specified behavior is:

1. `autoM2MView(target_view, target_change) = target_view OR target_change`.
2. `autoM2MWrite(target_change) = target_change`.
3. If `target_view = true` and `target_change = false`, then `autoM2MWrite(target_change) = false`.
4. If `autoM2MWrite(target_change) = false`, `applyInlinePost(false, original_rel, submitted_rel) = original_rel`.
5. If `autoM2MWrite(target_change) = true`, `applyInlinePost(true, original_rel, submitted_rel) = submitted_rel`.

## Relation To V1 Code

V1 implements the contract in `repo/django/contrib/admin/options.py`:

- `has_view_permission()` for auto-created intermediary models calls `_has_any_perms_for_target_model(request, ['view', 'change'])`.
- `has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` call `_has_any_perms_for_target_model(request, ['change'])`.
- `get_inline_formsets()` passes those booleans into `InlineAdminFormSet`, making view-only rows read-only.
- `_create_formsets()` bypasses validation for view-only inline initial forms and checks deletion only through `inline.has_delete_permission()`.
- `InlineModelAdmin.get_formset()` wraps forms with `has_changed()` returning false when the user lacks add/change permission.

## Preconditions

- The inline model is an auto-created many-to-many intermediary model.
- The target model is the non-parent model referenced by the intermediary foreign keys, matching the pre-existing lookup behavior.
- This is a partial correctness specification of the permission and save effect. It does not prove request routing, database transaction termination, or template rendering in full.

## Out Of Scope

- Custom explicit through models, which have their own model permissions.
- Non-m2m inline models.
- Full HTML rendering.
- Termination and performance.
