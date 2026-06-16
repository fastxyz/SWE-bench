# Baseline Notes

## Root cause

During deserialization, `build_instance()` constructs a temporary model instance
with `Model(**data)` so it can call `natural_key()` and look up an existing row
when the fixture omits a primary key. That temporary instance did not have its
database state set.

If a model's `natural_key()` follows a foreign key, the related descriptor uses
the instance database state as a router hint. With `_state.db` unset, related
object loading falls back to the default database. Loading the fixture into a
non-default database can therefore fail even though the related object exists in
the target database.

## Files changed

`repo/django/core/serializers/base.py`

Set the temporary instance's `_state.db` to the deserialization database before
calling `natural_key()`. This ensures any related-object access performed while
computing the natural key uses the same database that `loaddata --database`
targets, matching the later `get_by_natural_key()` lookup.

## Assumptions and alternatives

I assumed `build_instance()` should preserve the existing `Model(**data)`
construction behavior and only add the missing database context. That keeps field
defaults, initialization behavior, and custom model logic as close as possible to
the previous path.

I considered using `Model.from_db()` to create a database-bound instance, but
that would mark the temporary object as loaded from the database and could invoke
custom `from_db()` behavior. It can also differ from `Model(**data)` for omitted
fields. Since the failure is only caused by the missing database state, directly
setting the state on the serializer's temporary instance is the narrower fix.

I did not modify tests because the task requires changes to non-test source code
only. I also did not run the test suite or execute project code, following the
task constraints.
