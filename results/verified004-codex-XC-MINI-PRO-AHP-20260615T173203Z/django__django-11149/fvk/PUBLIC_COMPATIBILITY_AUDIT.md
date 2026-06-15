# Public Compatibility Audit

Status: pass.

## Changed public symbols

No public method signatures changed.

The public override hooks remain:

- `InlineModelAdmin.has_add_permission(self, request, obj)`
- `InlineModelAdmin.has_change_permission(self, request, obj=None)`
- `InlineModelAdmin.has_delete_permission(self, request, obj=None)`
- `InlineModelAdmin.has_view_permission(self, request, obj=None)`

## Added private helpers

V1 added private helpers on `InlineModelAdmin`:

- `_get_target_model_opts(self)`
- `_has_any_perms_for_target_model(self, request, perms)`

These helpers are internal implementation details and do not alter documented signatures.

## Public callsites and overrides

The existing callsites in `ModelAdmin.get_inline_instances()`, `ModelAdmin.get_inline_formsets()`, `ModelAdmin._create_formsets()`, and `InlineModelAdmin.get_formset()` continue calling the same public hooks with the same argument shape.

Subclass overrides of the public hooks remain compatible because no caller now passes extra arguments and no hook signature changed.

## Behavior compatibility

For explicit through models and ordinary inline models, behavior is unchanged because V1 changes only the `if self.opts.auto_created` branch.

For auto-created many-to-many through models, target model `change` permission still permits add/change/delete of relationship rows, matching existing public tests. Target model `view` alone now permits read-only display but no relationship write.
