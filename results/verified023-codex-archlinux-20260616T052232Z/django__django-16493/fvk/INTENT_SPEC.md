# Intent Spec

Status: constructed for audit; not machine-checked.

## Required behavior

I1. `FileField.storage` accepts either a storage object or a callable returning
a storage object.

I2. `FileField.__init__()` may evaluate callable storage for runtime use, but
`FileField.deconstruct()` must serialize the field in a way that can recreate
the original field configuration for migrations.

I3. If the original `storage` argument was a callable, `deconstruct()` must use
the original callable as the serialized `storage` kwarg, not the evaluated
storage result.

I4. The callable-storage rule applies even when the callable evaluates to
`default_storage`; this is the issue's reported missing case.

I5. If no explicit storage argument is supplied, or the effective non-callable
storage value is the implicit `default_storage`, `deconstruct()` may omit the
`storage` kwarg as a default-value omission.

I6. Explicit non-default storage objects must still be serialized as the
storage object.

I7. Existing public API shape must remain compatible: no signature change to
`FileField.__init__()` or `FileField.deconstruct()`, no test-file changes, and
no migration serialization shape change except the corrected presence of
`storage=<callable>` for callable storage arguments.

## Out of scope

This audit does not prove storage backend behavior, file saving, upload path
generation, or migration writer import serialization. It covers the
`FileField.deconstruct()` decision about whether the `storage` kwarg is omitted
or included and which value is used when it is included.
