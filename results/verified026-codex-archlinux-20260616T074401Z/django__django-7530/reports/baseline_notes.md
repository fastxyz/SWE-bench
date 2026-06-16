# Baseline Notes

## Root cause

`makemigrations` checks migration history only on databases where at least one
model is allowed to migrate. The check built that decision by iterating every
installed app label and then calling `apps.get_models(app_label)`.

In this Django version, `Apps.get_models()` doesn't accept an app label; its
first positional argument is `include_auto_created`. Passing the app label
therefore returned all project models for each app label, producing invalid
`(app_label, model_name)` pairs for database routers.

## Changed files

`repo/django/core/management/commands/makemigrations.py`

Changed the consistency-check router probe to iterate installed `AppConfig`
objects and call `app_config.get_models()` for each one. This keeps each
`allow_migrate()` call scoped to a real app/model pairing while preserving the
existing check that at least one model must be migratable before validating a
database's migration history.

`reports/baseline_notes.md`

Added this report to document the diagnosis, change, assumptions, and rejected
alternatives.

## Assumptions and alternatives

I assumed the intended behavior is to keep the existing `allow_migrate()` call
shape, including `model_name=model._meta.object_name`, and only fix the invalid
pairing described in the issue. Changing the model-name casing or adding a
`model` hint would be a broader router API behavior change than the reported
bug requires.

I considered iterating `apps.get_models()` once and using
`model._meta.app_label` for the app label. That would also avoid the
cross-product, but iterating each `AppConfig` with `app_config.get_models()`
matches the issue wording more directly and makes the relationship between app
labels and models explicit.

I rejected changes to migration loader consistency checking because that code
only validates already-selected databases. The incorrect router calls happen
before `loader.check_consistent_history()` is invoked.
