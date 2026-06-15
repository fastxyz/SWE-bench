# Baseline Notes

## Root cause

Migration serialization of class objects still used `__name__` in
`django.db.migrations.serializer.TypeSerializer`. This drops any containing
class names from nested classes. When a field stores a nested enum/model choice
class as a value, for example `Thing.State`, `serializer_factory()` treats that
value as a `type` and serializes it through `TypeSerializer`, producing
`app.models.State` instead of `app.models.Thing.State`.

Other related paths had already been updated to use `__qualname__`, including
`Field.deconstruct()` for field subclasses and `EnumSerializer` for enum
members. Those paths do not cover enum class objects passed as field arguments.

## Changed files

`repo/django/db/migrations/serializer.py`

Changed `TypeSerializer.serialize()` to use `self.value.__qualname__` for
non-builtin class references. This preserves the existing handling for built-in
types such as `list` and special cases such as `models.Model`, while keeping the
containing class path for nested importable classes.

## Assumptions and alternatives considered

I assumed the intended serialized form for any importable nested class is the
module plus the qualified class name, matching Python's attribute lookup syntax
and the existing enum member serializer behavior.

I considered changing `EnumSerializer`, but rejected that because the failing
value is the enum class itself, not an enum member. The serializer factory sends
class objects to `TypeSerializer`.

I considered changing field deconstruction, but rejected that because
`Field.deconstruct()` already uses `__qualname__` in this checkout and the
remaining failure described in the issue is class-value serialization.

I did not run tests or code, per the benchmark instructions.
