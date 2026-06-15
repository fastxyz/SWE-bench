# Baseline Notes

## Root cause

`ForeignObject.deconstruct()` serialized string-based related model references with `self.remote_field.model.lower()`. For a lazy relation such as `DJ_RegLogin.Category`, that lowercased both the model name and the app label, producing `dj_reglogin.category`. App labels are case-sensitive in migrations, so the migration state later tried to resolve an app named `dj_reglogin` instead of the installed `DJ_RegLogin` app.

## Changed files

`repo/django/db/models/fields/related.py`

- Changed the string-relation serialization in `ForeignObject.deconstruct()` so it splits the `app_label.ModelName` reference and lowercases only the model name component.
- This keeps Django's existing lowercase model-name convention for migration references while preserving the original app label case.

`reports/baseline_notes.md`

- Added this report with the root cause, changed file list, assumptions, and rejected alternatives required by the task.

## Assumptions

- String relations that reach `ForeignObject.deconstruct()` are normalized to the `app_label.ModelName` form by model setup, matching the surrounding code's handling of lazy related model references.
- The intended compatibility behavior is to preserve app label case, not to make app registry lookups case-insensitive.
- No test files should be modified, and no tests or project code should be run in this benchmark environment.

## Alternatives considered and rejected

- Making app label lookup case-insensitive was rejected because app labels have historically been case-sensitive in migrations and that broader behavioral change could affect existing projects.
- Leaving the whole relation string unchanged was rejected because non-string model references are serialized with `label_lower`, so model names should continue to be lowercased for consistency.
- Changing `ForeignKey.deconstruct()` directly was rejected because the incorrect `to` value is produced in the shared `ForeignObject.deconstruct()` implementation before `ForeignKey.deconstruct()` returns.
