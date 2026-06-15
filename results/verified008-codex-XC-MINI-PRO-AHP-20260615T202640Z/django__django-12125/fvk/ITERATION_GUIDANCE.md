# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change:

`TypeSerializer.serialize()` uses `self.value.__qualname__` for non-builtin class
paths.

This decision is justified by FINDINGS F-001 through F-005 and proof obligations
PO-001 through PO-008.

## Recommended Code Action

No additional production code edit is required for the public issue.

Rejected edits:

- Change `EnumSerializer`: rejected by F-004 and PO-007 because enum class
  objects are routed to `TypeSerializer`, while enum members already serialize
  with `__qualname__`.
- Change `Field.deconstruct()`: rejected by F-005 and PO-008 because the checked
  source already uses `__qualname__`.
- Add a local-class `<locals>` guard in `TypeSerializer`: recorded as residual
  risk F-006, but not required by the public issue's importable nested class
  domain.

## Suggested Future Tests

Do not edit tests in this benchmark. Future public tests should cover:

- `MigrationWriter.serialize(Thing.State)` where `State` is nested on an
  importable model/class, expecting `module.Thing.State`.
- A field argument that stores a nested enum class, expecting generated migration
  code with `module.Thing.State`.
- A top-level class object, expecting unchanged `module.ClassName`.
- Builtin classes and special cases, expecting unchanged output.

## Suggested Future Question

If the migration serializer's public contract is expanded beyond importable
class references, ask: should function-local class objects fail immediately with
`ValueError`, matching local function handling, rather than returning a raw
`<locals>` qualified path?
