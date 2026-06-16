# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

| Symbol | Public Surface | Compatibility Result |
|---|---|---|
| `sphinx.builders.gettext.Message.__init__` | Existing constructor signature remains `(text, locations, uuids)`. | Compatible. Behavior only removes duplicate location tuples from stored `locations`. |
| `sphinx.builders.gettext.Catalog.__iter__` | Existing iterator still yields `Message` objects in catalog insertion order. | Compatible. Location source strings are normalized before storage, which preserves rendered output for retained entries. |
| `_unique_locations` | New private helper. | No public compatibility impact. |

## Callsite/Override Audit

- No method signature was changed.
- No virtual dispatch call was changed.
- No subclass override contract was introduced or altered.
- The gettext template still consumes `message.locations` as `(source, line)`
  pairs and applies the existing `relpath` filter.

## Compatibility Finding

No public compatibility blocker was found.
