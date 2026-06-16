# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

1. Generated gettext POT output must not contain duplicate location comment
   lines for a single message.
2. Duplicate detection must account for source paths that are textually
   different before rendering but represent the same final output location.
3. The fix should be in Sphinx's gettext message construction path, especially
   `sphinx/builders/gettext.py`, because the issue and hint identify
   `Message.__init__()` and `Catalog.__iter__()` as the relevant path.
4. The existing message text, message order, UUID collection, and final relative
   location formatting should be preserved except for removing duplicate
   location entries.

## Domain

The specified domain is one gettext catalog message at a time:

- Input metadata is a finite ordered sequence of triples
  `(source_path, line_number, uuid)` as stored in `Catalog.metadata[message]`.
- `source_path` is a filesystem path accepted by Sphinx's `relpath()` utility.
- `line_number` is the integer line value already recorded on the docutils
  origin node.
- `uuid` is opaque data and is not used to determine location identity.

## Required Observable Behavior

For each message, the rendered location comment sequence must be the
preserve-order unique sequence of rendered `(source_path, line_number)` pairs.
Equivalently, if two metadata entries render to the same `#: path:line` line,
only the first such rendered line may appear in `message.locations`.

## Out Of Scope For This Issue

- Sorting message locations or messages.
- Changing wrapping behavior in Babel's PO writer.
- De-duplicating UUID comment lines when `gettext_uuid` is enabled.
- Modifying tests or executing test/K tooling.
