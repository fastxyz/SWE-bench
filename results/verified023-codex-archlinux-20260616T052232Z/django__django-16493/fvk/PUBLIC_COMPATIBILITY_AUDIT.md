# Public Compatibility Audit

Status: constructed for audit; not machine-checked.

## Changed public symbol

`django.db.models.fields.files.FileField.deconstruct`

## Compatibility result

Pass.

## Details

- Signature unchanged: `def deconstruct(self)`.
- Return shape unchanged: `(name, path, args, kwargs)`.
- Existing default omission preserved for implicit/default storage.
- Existing direct non-default storage serialization preserved.
- Existing callable non-default storage serialization preserved.
- Corrected behavior: callable storage returning `default_storage` now includes
  `kwargs["storage"]` with the original callable.
- No public callers need updates because callers consume the same
  deconstruction tuple shape.
- No subclass override contract changed. `ImageField.deconstruct()` delegates to
  `FileField.deconstruct()` and benefits from the same corrected storage kwarg
  behavior without a signature or return-shape change.

## Public callsites and overrides checked

- `ImageField.deconstruct()` in `repo/django/db/models/fields/files.py` calls
  `super().deconstruct()` and then adds image-specific kwargs.
- Public tests under `repo/tests/file_storage/` expect callable storage
  deconstruction to return the original callable for non-default storage.
- Field deconstruction docs require kwargs that can reconstruct field state and
  allow omitting only values that are not necessary, such as defaults.
