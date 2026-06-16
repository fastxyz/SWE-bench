# Baseline Notes

## Root cause

`MigrationAutodetector.only_relation_agnostic_fields()` compares model field definitions while intentionally ignoring the related model target. It identified relational fields from `field.remote_field`, then unconditionally deleted the serialized `to` keyword from the field's deconstruction.

Custom relation fields can hardcode their target model and intentionally omit `to` from `deconstruct()` so migrations do not serialize that implementation detail. In that case the field is still relational, but the deconstructed kwargs do not contain `to`, so the unconditional deletion raised `KeyError`.

## Changed files

`repo/django/db/migrations/autodetector.py`

Changed the `del deconstruction[2]['to']` statement to `deconstruction[2].pop('to', None)`. This keeps the existing behavior for normal relation fields where `to` is present, while allowing custom fields that omit `to` from their deconstruction.

`reports/baseline_notes.md`

Added this report documenting the root cause, changed files, assumptions, and rejected alternatives.

## Assumptions and alternatives considered

I assumed the autodetector should remain relation-agnostic for model rename detection even when a custom field chooses not to serialize `to`. The field object's `remote_field` is the source of truth for whether the field is relational, but the deconstructed kwargs are allowed to be narrower than the field's runtime attributes.

I considered changing the condition to check whether `'to' in deconstruction[2]` before deleting. That would also fix the crash, but `pop('to', None)` is the minimal equivalent and matches the intended "remove if present" behavior.

I did not change later autodetector code that reads `old_field_dec[2]['to']` during renamed-field generation because that path already guards with `'to' in old_field_dec[2]` and is unrelated to the reported crash.
