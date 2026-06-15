# FVK Specification: FileField Callable Storage Deconstruction

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Target code:

- `repo/django/db/models/fields/files.py`
- `FileField.__init__()`
- `FileField.deconstruct()`
- `ImageField.deconstruct()` only through inheritance of `FileField.deconstruct()`

The proof models the storage-specific behavior that caused the issue. It treats `Field.deconstruct()` as a trusted superclass frame that returns an initial `(name, path, args, kwargs)` and focuses on how `FileField` adds `upload_to` and `storage`.

## Intent Spec

Intent-only obligations from public evidence:

- I1. A callable may be supplied as `storage` for `FileField` and `ImageField`.
- I2. Runtime file operations still need `field.storage` to be a `Storage` instance.
- I3. Deconstruction must not evaluate the callable storage provider.
- I4. Deconstruction must serialize a reference to the original callable storage provider, not the evaluated `Storage` instance.
- I5. The above must hold even when the callable selects storage dynamically at runtime.
- I6. Existing non-callable behavior is a frame condition: explicit non-default storage is serialized as before; default storage is omitted as before; `upload_to` remains serialized by reference/value as before.

## Public Evidence Ledger

E1. Source: prompt. Quote: "FileField with a callable storage parameter should not actually evaluate the callable when it is being deconstructed." Obligation: I3.

E2. Source: prompt. Quote: "The correct behavior should be to return a reference to the original callable during deconstruction." Obligation: I4.

E3. Source: prompt. Quote: "selecting different storages for different environments." Obligation: I5, because the migration representation must preserve the selection hook rather than freezing one selected storage.

E4. Source: prompt. Quote: "FileField or ImageField." Obligation: I1 applies to `ImageField` through `FileField`.

E5. Source: implementation. `FieldFile.__init__()` and file operations use `field.storage`. Obligation: I2 explains why the constructor may still evaluate the callable for runtime state; implementation evidence only, not a migration serialization spec.

E6. Source: implementation. Existing `FileField.deconstruct()` writes `upload_to`, omits default `max_length`, serializes non-default `storage`, and `ImageField.deconstruct()` calls `super().deconstruct()`. Obligation: I6 frame condition.

## Formal Model

The mini semantics are in `fvk/mini-python-filefield.k`; the K claims are in `fvk/filefield-storage-spec.k`.

Model values:

- `defaultStorage`: Django's `default_storage` singleton.
- `storage(S)`: a concrete `Storage` instance.
- `callable(C, R)`: original callable provider named `C` returning result `R`.
- `invalid`: a callable result that is not a `Storage`.
- `field(runtimeStorage, maybeCallable, uploadTo)`: the modeled field state after construction.
- `kwargs(...)`: deconstruction keyword map.

Important abstraction boundary:

- The model preserves identity distinctions between the original callable and the returned storage instance.
- The model tracks whether a callable is called during construction and whether `deconstruct()` calls it.
- The model does not execute real Python descriptors, migration serializers, or filesystem storage methods.

## Formal Claims In English

C1. Constructor callable preservation. For a callable storage provider `C` returning storage `S`, construction reaches a field whose runtime storage is `S`, whose preserved callable is `C`, and whose call count for `C` increased exactly once.

C2. Callable deconstruction. For any field containing preserved callable `C`, `deconstruct()` reaches kwargs containing `storage=C` and `upload_to=U`, and the callable call count is unchanged during deconstruction.

C3. Callable returning default storage. If callable `C` returns `defaultStorage`, `deconstruct()` still reaches kwargs containing `storage=C`; it does not omit storage merely because the runtime storage is default.

C4. Non-callable explicit storage frame. For a field with no preserved callable and runtime storage `S != defaultStorage`, `deconstruct()` reaches kwargs containing `storage=S`.

C5. Default storage frame. For a field with no preserved callable and runtime storage `defaultStorage`, `deconstruct()` reaches kwargs containing `upload_to=U` and no `storage` entry.

C6. Invalid callable result. If callable `C` returns `invalid`, construction reaches the existing `TypeError` path rather than creating a deconstructible field.

## Adequacy Audit

- C1 vs I1/I2: pass. Runtime storage remains an evaluated `Storage` instance while the original callable is retained.
- C2 vs I3/I4: pass. The formal result contains the original callable and proves zero deconstruction-time callable invocations.
- C3 vs I4/I5: pass. Dynamic selection is preserved even when the selected runtime storage is the default.
- C4 vs I6: pass. Non-callable explicit storage behavior is unchanged.
- C5 vs I6: pass. Default storage omission is unchanged.
- C6 vs I2/I6: pass. Existing constructor validation behavior is preserved.

No formal claim is supported only by legacy behavior that conflicts with the public issue.

## Public Compatibility Audit

- Public signatures: unchanged for `FileField.__init__()`, `FileField.deconstruct()`, and `ImageField.deconstruct()`.
- Public return shape: unchanged four-tuple from `deconstruct()`.
- New attribute: `_storage_callable` is private and only set on fields constructed with callable storage.
- Subclasses/overrides: `ImageField.deconstruct()` delegates to `FileField.deconstruct()` and benefits from the same storage kwargs. No virtual dispatch call signature was changed.
- Producer/consumer shape: migrations still receive a keyword named `storage`; only its value changes for callable storage, matching the issue intent.

Compatibility status: pass.
