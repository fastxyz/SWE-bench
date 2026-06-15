# Intent Spec

Scope: audit of the V1 fix for `django__django-11149`, focused on Django admin inlines whose `model` is an auto-created `ManyToManyField.through` model.

## Intent-only obligations

I1. A staff user with only view permissions for the parent model and the many-to-many target model must not be able to add, remove, or otherwise edit the many-to-many relationship through an admin inline.

Evidence: `benchmark/PROBLEM.md` says "my user with view only permissions can now add or remove these items at will" and "You can adjust the M2M. You shouldn't be able to."

I2. View permission is still read access. The inline may be displayed for a view-only user, but its submitted data must not be accepted as a relationship edit.

Evidence: the issue is framed as "view only permissions" and "view permissions feature", not as a request to hide viewable relationships.

I3. For auto-created many-to-many intermediary models, Django must continue using the related target model's permissions because the intermediary model has no independent add/change/delete/view permissions.

Evidence: existing admin inline permission tests for auto-created m2m through models state that target `change_book` permission enables add/change/delete of the relationship rows, while target `add_book` alone does not.

I4. For non-auto-created inline models, existing `InlineModelAdmin` permission behavior is outside the intended change.

Evidence: the issue title and reproduction are specific to "auto-created ManyToManyFields" and `Report.photos.through`.

I5. No public method signature or override contract should change.

Evidence: Django admin documents `InlineModelAdmin.has_add_permission(request, obj)`, `has_change_permission(request, obj=None)`, and `has_delete_permission(request, obj=None)` as public override hooks.
