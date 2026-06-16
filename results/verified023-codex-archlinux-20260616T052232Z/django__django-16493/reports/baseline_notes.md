# Baseline Notes

## Root cause

`FileField.__init__()` evaluates callable `storage` arguments and stores the
original callable on `_storage_callable` for later deconstruction. However,
`FileField.deconstruct()` decided whether to include the `storage` kwarg by
comparing `self.storage` to `default_storage`. When a callable returned
`default_storage`, `self.storage` was the evaluated default object, so the
comparison treated the field as if no custom storage argument had been supplied
and omitted the callable from the deconstructed field.

That made migrations unstable for callable storage providers that can return
`default_storage`, because the migration serialization depended on the
callable's evaluated result instead of the model field argument.

## Files changed

`repo/django/db/models/fields/files.py`

Changed `FileField.deconstruct()` to first choose the storage value that should
be serialized:

- `_storage_callable` when the field was constructed with a callable storage
  argument.
- `self.storage` otherwise.

The method now uses that same value for both the comparison with
`default_storage` and the `kwargs["storage"]` assignment. This preserves the
existing omission of the implicit default storage while ensuring callable
storage arguments are serialized as the original callable, even if the callable
evaluates to `default_storage`.

## Assumptions and alternatives considered

I assumed the migration deconstruction contract should reflect the original
`storage` argument, not the runtime result of calling it. This matches the
existing `_storage_callable` preservation in `FileField.__init__()` and the
issue hint that `_storage_callable` should be used unconditionally when present.

I considered special-casing only callables that return `default_storage`, but
that would duplicate the current callable handling and leave two comparison
paths. Using `getattr(self, "_storage_callable", self.storage)` once is smaller
and keeps all callable storage deconstruction behavior consistent.

I did not modify tests because the task forbids test file changes. I also did
not run tests or project code because the task explicitly says this session has
no execution environment.
