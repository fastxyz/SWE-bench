# Baseline Notes

## Root cause

`FunctionTypeSerializer.serialize()` has a special branch for methods bound to a
class, including class methods. That branch built the migration reference with
`klass.__name__`, which only contains the innermost class name. For a class
method on a nested class such as `Profile.Capability.default`, this dropped the
outer `Profile` qualifier and serialized the callable as
`appname.models.Capability.default`.

The serializer already uses `__qualname__` in other places where nested classes
must be preserved. Using the class's qualified name in this branch keeps the
existing output for top-level classes and includes outer class names for nested
classes.

## Files changed

`repo/django/db/migrations/serializer.py`

Changed `FunctionTypeSerializer.serialize()` so the class-bound method path uses
`klass.__qualname__` instead of `klass.__name__`. This makes nested class methods
serialize to importable migration references such as
`appname.models.Profile.Capability.default`.

## Assumptions and alternatives considered

I assumed the intended behavior is to serialize class-bound methods in the same
module-qualified style as before, with only the class-name component expanded to
its qualified name. This preserves compatibility for non-nested classes because
their `__name__` and `__qualname__` are identical.

I considered adding broader validation for class-bound methods whose qualified
name contains local-scope markers such as `<locals>`, but rejected it as outside
the reported issue. The existing branch did not perform that validation, and the
minimal fix is to preserve nested class qualification without changing error
behavior for unrelated cases.

I did not add or modify tests because the benchmark instructions prohibit
changing test files.
