# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None.

## Changed internal symbols

`django.db.models.sql.query.Query.deferred_to_data()`

- Signature unchanged.
- Return protocol unchanged: it still mutates the supplied `target` mapping.
- Input protocol unchanged: it still reads `self.deferred_loading`, model
  metadata, and field paths.
- Public callers remain compatible because the edit normalizes an internal local
  variable before populating the existing mask.

## Callsite and override audit

No public callsite or subclass override needs an update. The changed method is an
internal helper and no virtual dispatch shape or keyword argument was changed.

## Test-file audit

No test files were modified. A regression test matching the issue would be
appropriate when test edits are allowed, but this task forbids changing tests.

