# Baseline Notes

## Root cause

`MigrationAutodetector._get_dependencies_for_foreign_key()` correctly detects that an explicit many-to-many `through` model needs an additional migration dependency, but it resolved that additional dependency from `remote_field_model`, the many-to-many target model, instead of from `field.remote_field.through`.

For a field such as `ManyToManyField("variavel.VariavelModel", through="fonte_variavel.FonteVariavelModel")`, this caused the generated migration for `fonte` to depend on `variavel` but not on `fonte_variavel`. During migration application, the historical app registry could render `FonteModel` before the through model existed, leaving `field.remote_field.through` as a string. `schema_editor.create_model()` then accessed `field.remote_field.through._meta` and raised `AttributeError: 'str' object has no attribute '_meta'`.

## Files changed

`repo/django/db/migrations/autodetector.py`

Changed the through-model dependency calculation to resolve `field.remote_field.through` instead of reusing `remote_field_model`. This makes migrations that add or create many-to-many fields depend on the actual explicit intermediary model, including when it lives in another app.

`reports/baseline_notes.md`

Added this report with the root cause, changed files, assumptions, and rejected alternatives required by the benchmark task.

## Assumptions and alternatives considered

I assumed the intended behavior is for the autodetector to generate a dependency on every explicit through model referenced by a many-to-many field, regardless of app label. This matches the existing structure of `_get_dependencies_for_foreign_key()`, which already has a separate branch for `through` dependencies.

I considered changing `schema_editor.create_model()` to tolerate unresolved string `through` references, but rejected that because schema editing should receive rendered historical model classes with dependencies already satisfied. Silently skipping or special-casing unresolved through strings there would hide an invalid migration state and could mask ordering errors.

I also considered changing `ProjectState` model reloading to include through models as direct related models. That may affect broader cache behavior, but it would not fix the generated migration's missing cross-app dependency. The narrow root cause is the autodetector resolving the through dependency from the wrong model reference.
