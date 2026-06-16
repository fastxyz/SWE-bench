# Baseline Notes

## Root Cause

The gettext builder records each translatable message location from
`origin.source` as-is in `Catalog.metadata`. Those source values can refer to
the same file using different textual paths, such as an absolute path and a
relative path. The output template later converts all locations with
`relpath(source, outdir)`, so distinct raw paths can collapse into the same
visible `#: path:line` entry in the generated POT file.

Because uniqueness was not applied after normalizing source paths, repeated
visible locations could be emitted for a single message even when the final
location lines were identical.

## Changed Files

`repo/sphinx/builders/gettext.py`

- Added `_unique_locations()` to remove duplicate `(source, line)` pairs while
  preserving the original traversal order.
- Changed `Message.__init__()` to store de-duplicated locations, preventing exact
  duplicate location tuples from being emitted.
- Changed `Catalog.__iter__()` to normalize each source path with Sphinx's
  existing `relpath()` and `canon_path()` utilities before creating a `Message`.
  This makes locations that point at the same file compare equal before
  de-duplication, while preserving the renderer's existing output behavior.

## Assumptions and Alternatives

- I assumed source paths should be normalized relative to the current working
  directory because the issue hint identifies that as the path basis that exposes
  equivalent absolute and relative sources before rendering.
- I preserved the first occurrence of each normalized location instead of using
  `set(locations)` directly, because unordered set conversion would make POT
  output less stable.
- I did not change Babel's PO parser or writer. Sphinx is generating these POT
  files through its own gettext template here, and the duplicated locations are
  already present in the message data handed to that template.
- I did not alter location wrapping or message sorting behavior. Those were
  mentioned as related observations in the issue text, but they are separate
  behavior changes from removing duplicate message locations.
- I did not run tests or project code, as required by the benchmark constraints.
