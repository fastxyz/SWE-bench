# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None.

## Changed private/internal implementation points

`LiteralIncludeReader.read()` in `repo/sphinx/directives/code.py` changed the order of internal filters in the non-diff branch only.

## API and callsite audit

- `LiteralIncludeReader.__init__(filename, options, config)`: unchanged.
- `LiteralIncludeReader.read(location=None)`: unchanged signature and return type.
- `LiteralIncludeReader.prepend_filter`, `append_filter`, and `dedent_filter`: unchanged signatures and local behavior.
- `LiteralInclude.run()`: unchanged caller; it still receives `(text, lines)` from `reader.read(location=location)`.
- Directive option names: unchanged.
- `diff` option branch: unchanged because `show_diff()` is selected before the filter list.

## Compatibility result

No public compatibility risk was found. The change is behavioral only for the previously defective combined option case where `dedent` was applied to synthetic `prepend`/`append` lines.
