# FVK Notes

## Decision

V1 stands unchanged. The audit produced no source edit beyond the existing V1 patch.

## Trace To Findings And Obligations

F1 identifies the original bug: auto-created many-to-many inline write hooks delegated to view permission. PO2 proves the V1 correction: add/change/delete now depend on target `change`, so target `view` alone cannot authorize writes.

PO3 and PO4 cover the path beyond the permission methods. `get_inline_formsets()` passes the corrected booleans into the admin formset wrapper, `_create_formsets()` bypasses unauthorized initial-form validation and deletion, and the wrapped inline form `has_changed()` ignores unauthorized existing or new form edits. This is why no additional save-path source change was needed.

F2 and PO5 explain why V1 uses target `change` for all relationship row writes instead of target `add` or `delete`. Existing public tests for auto-created m2m inlines establish target `change` as the write gate, and adding/removing a relationship row is not adding/deleting the target object.

F3 and PO1 explain why the inline remains viewable. The public issue objects to editing with view-only permissions, not to read-only display.

F4 and PO6 explain why no parent-change gate was added. That would alter broader admin inline behavior; the public issue is fixed once users with only view permissions cannot edit the auto-created m2m relation.

F5 and PO7 record the proof status. The `.k` artifacts and proof were constructed but not machine-checked because the task forbids running K tooling.

## Files

- Kept unchanged: `repo/django/contrib/admin/options.py` after V1.
- Added FVK artifacts under `fvk/`.
- Added this report: `reports/fvk_notes.md`.
