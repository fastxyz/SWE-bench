# Baseline Notes

## Root cause

`FileField.__init__()` accepted a callable `storage` argument, immediately called it, and replaced `self.storage` with the returned `Storage` instance. `FileField.deconstruct()` later used `self.storage` when building migration kwargs, so it serialized the evaluated storage instance instead of the original callable. That made migrations freeze the storage selected at deconstruction time and defeated the documented ability to choose storage dynamically at runtime.

## Changed files

`repo/django/db/models/fields/files.py`

Stored the original callable in `self._storage_callable` before evaluating it. Runtime file behavior still uses the evaluated `Storage` instance, and the existing type check still validates the callable result.

Updated `FileField.deconstruct()` to serialize `self._storage_callable` when present, falling back to `self.storage` for non-callable storage values. This preserves existing behavior for explicit storage instances and default storage while returning a reference to the callable for callable storage arguments.

## Assumptions and alternatives

I assumed that the callable should be preserved whenever the effective storage argument is callable, even if it returns `default_storage`, because the caller explicitly supplied a runtime selection hook.

I considered delaying callable evaluation until later file access, but rejected that because the current field API exposes `field.storage` as a `Storage` instance and existing validation depends on evaluating the callable during field construction.

I also considered changing only `deconstruct()`, but the original callable was no longer available there. Keeping a private reference in the field is the smallest targeted change.
