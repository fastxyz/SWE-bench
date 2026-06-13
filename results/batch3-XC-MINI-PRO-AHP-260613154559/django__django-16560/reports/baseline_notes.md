# Baseline notes — django__django-16560

## Issue

> Allow to customize the `code` attribute of `ValidationError` raised by
> `BaseConstraint.validate`.

It was already possible to customize the `violation_error_message` of a
`ValidationError` raised by a constraint, but not its `code`. The request is to
add a `violation_error_code` parameter to `BaseConstraint` (and its subclasses)
so a descriptive error code can be supplied directly, mirroring the existing
`violation_error_message` mechanism and the `code`/`message` pairing used by
form/field validators.

## Root cause

`BaseConstraint` (and the subclasses `CheckConstraint`, `UniqueConstraint`, and
the PostgreSQL `ExclusionConstraint`) only stored a `violation_error_message`.
When a constraint was violated during model validation, `validate()` raised
`ValidationError(self.get_violation_error_message())` with **no** `code`
argument, so the resulting error always had `code=None`. There was no public
hook to set the code short of subclassing and re-raising.

## Changes

### `django/db/models/constraints.py`
- Added a class attribute `violation_error_code = None` on `BaseConstraint`.
- Added a keyword-only `violation_error_code=None` parameter to
  `BaseConstraint.__init__` and stored it on the instance when provided. Updated
  the `RemovedInDjango60Warning` comment showing the post-deprecation signature.
  The deprecated positional-argument list was intentionally left as
  `["name", "violation_error_message"]` — `violation_error_code` is brand new and
  was never a historical positional argument, so it stays keyword-only.
- `BaseConstraint.deconstruct()` now emits `violation_error_code` in `kwargs`
  when it is not `None`, so the value survives `clone()` and migration
  serialization. (`clone()` is unchanged; it round-trips through `deconstruct`.)
- `CheckConstraint`: threaded `violation_error_code` through `__init__`, passed
  `code=self.violation_error_code` to the `ValidationError` raised in
  `validate()`, and added the code to `__eq__` and `__repr__`.
- `UniqueConstraint`: same threading through `__init__`, `__eq__`, `__repr__`,
  and added `code=self.violation_error_code` to the two `ValidationError` raises
  that use `get_violation_error_message()` (the expressions branch and the
  conditional branch).

### `django/contrib/postgres/constraints.py`
- `ExclusionConstraint` extends `BaseConstraint`, so it received the same
  treatment: `violation_error_code` in `__init__`, `__eq__`, `__repr__`, and
  `code=self.violation_error_code` on both `ValidationError` raises in
  `validate()`.

### Docs
- `docs/ref/models/constraints.txt`: updated the `BaseConstraint`,
  `CheckConstraint`, and `UniqueConstraint` signatures and added
  `violation_error_code` attribute sections (with `.. versionadded:: 5.0`).
- `docs/ref/contrib/postgres/constraints.txt`: updated the `ExclusionConstraint`
  signature and added a `violation_error_code` section.
- `docs/releases/5.0.txt`: added a "Models" feature note.

## Key design decision: the `UniqueConstraint` fields backward-compat path

`UniqueConstraint.validate()` has a special branch: when the constraint is
defined with `fields` (not `expressions`) and has no `condition`, it raises the
error produced by `instance.unique_error_message(...)` (code `"unique"` or
`"unique_together"`) for backward compatibility, **not**
`get_violation_error_message()`. I deliberately left this branch unchanged so
that `violation_error_code` is *not* applied there. This is consistent with the
existing behavior of `violation_error_message`, which is already documented as
"*not used* for `UniqueConstraint`s with `fields` and without a `condition`."
Applying the new code only where the custom message is already honored keeps the
two parameters behaving identically and avoids a behavior change for existing
field-based unique constraints. The docs for the new attribute call out this
same exclusion.

## Assumptions and rejected alternatives

- **Default value `None`.** Unlike `violation_error_message` (which has a
  `default_violation_error_message`), there is no sensible default code, so the
  attribute defaults to `None` and is only deconstructed when explicitly set —
  matching how `ValidationError(code=None)` already behaves.
- **No `get_violation_error_code()` getter.** `get_violation_error_message()`
  exists because the message needs `%(name)s` interpolation; a code needs no
  formatting, so `self.violation_error_code` is passed directly. Adding a getter
  would be unused ceremony.
- **`repr` ordering: code before message.** I placed the `violation_error_code`
  slot before `violation_error_message` (matching the `__init__` keyword order
  and alphabetical order). Because the new slot renders to `""` whenever the code
  is `None`, all pre-existing `repr` outputs (which never set a code) are
  unchanged, so existing repr expectations still hold.
- **Postgres `ExclusionConstraint` included.** The issue is phrased in terms of
  `BaseConstraint.validate`; `ExclusionConstraint` is a first-party subclass that
  raises constraint `ValidationError`s, so excluding it would leave an
  inconsistent API. I judged including it the minimal way to fully satisfy the
  request without unrelated refactoring.
