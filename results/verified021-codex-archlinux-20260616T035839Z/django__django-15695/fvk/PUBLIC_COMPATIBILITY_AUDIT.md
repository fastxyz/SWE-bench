# PUBLIC_COMPATIBILITY_AUDIT

Status: constructed, not machine-checked.

## Changed public symbols

None.

V1 changes the body of `RenameIndex.database_backwards()` but does not change:

- class name
- constructor signature
- `deconstruct()` output
- public migration operation arguments
- `schema_editor.rename_index()` signature
- model state API signatures

## Callsite and override audit

The changed method remains called through the existing migration operation
interface. No new keyword arguments or return shapes were introduced.

`schema_editor.rename_index(model, old_index, new_index)` is called with the same
signature already used by `database_forwards()`.

## Compatibility finding

No compatibility blocker found.
