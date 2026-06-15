# Baseline Notes

## Root cause

`InlineModelAdmin` special-cased auto-created many-to-many intermediary models because those models do not have their own permissions. Its `has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` methods delegated to `has_view_permission()` for these intermediary models. After Django added distinct view permissions, that made a user with only view permission on the related model look like they also had write permissions for the inline relationship rows.

For an inline using `Report.photos.through`, this meant a user with only view permissions on `Report` and `Photo` could submit changes to the through formset and add or remove m2m relations.

## Files changed

`repo/django/contrib/admin/options.py`

Changed `InlineModelAdmin` so auto-created many-to-many intermediary models still use the target model's permissions, but distinguish read and write checks:

- `has_view_permission()` accepts target model `view` or `change` permission.
- `has_add_permission()`, `has_change_permission()`, and `has_delete_permission()` require target model `change` permission.

I added small helper methods to identify the target model for the auto-created intermediary and to check one or more target model permission codenames. This keeps the existing target-model lookup behavior shared between the permission methods.

## Assumptions and alternatives

I assumed that modifying an auto-created many-to-many relationship is a change to the relationship, not an add or delete of the target model object. This matches the existing admin inline permission tests, where `change` permission on the target model enables adding, editing, and removing rows in the auto-created m2m inline, while target `add` permission alone does not.

I considered requiring target model `add` for adding relationship rows and target model `delete` for removing them. I rejected that because an m2m row does not create or delete the related object, and it would conflict with the existing behavior documented by the local tests.

I also considered blocking the inline entirely for view-only users. I rejected that because Django's view permission model should allow read-only display of related inline objects; the problem is write access through the inline formset, not read visibility.

No tests were run because the task instructions prohibit running tests or code in this environment.
