# Formal Spec In English

Status: constructed, not machine-checked.

## Claim C1: Stable Unique Helper

For any finite ordered list of locations, `_unique_locations()` returns the
first occurrence of each distinct location and omits later duplicates. The
result has no duplicate location tuples, and the relative order of retained
locations is the same as in the input.

## Claim C2: Catalog Message Location Construction

For each message in a catalog, `Catalog.__iter__()` maps each raw metadata entry
`(source, line, uuid)` to the normalized location
`(canon_path(relpath(source)), line)` before constructing a `Message`.

## Claim C3: Message Location Storage

`Message.__init__()` stores `_unique_locations(locations)`, so exact duplicate
normalized locations are removed before template rendering sees them.

## Claim C4: Rendered Location Uniqueness

For every pair of metadata entries that would render to the same final
`#: path:line` output line, the normalized locations passed into `Message` are
equal. Since `Message` de-duplicates equal locations, the rendered POT output
contains only the first occurrence of that location line.

## Claim C5: Rendering Preservation

For each retained entry, rendering the normalized source path relative to the
gettext output directory produces the same final location text as rendering the
original source path. Therefore V1 removes only duplicate location lines and does
not otherwise change the path text emitted for retained locations.

## Claim C6: Frame Conditions

The patch does not change message text, message insertion order, catalog
metadata collection, UUID collection, template escaping, or the existing
`GettextRenderer._relpath()` formatting rule.
