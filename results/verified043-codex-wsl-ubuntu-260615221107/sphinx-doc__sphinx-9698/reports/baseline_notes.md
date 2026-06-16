# Baseline Notes

## Root cause

`py:method` with the `:property:` option disables the displayed argument list through
`PyMethod.needs_arglist()`, but its index text still came from the method-specific
formatting path in `PyMethod.get_index_text()`. That property branch used
`'%s() (%s property)'`, so the generated index entry included callable parentheses
even though the directive was explicitly describing a property.

## Changed files

- `repo/sphinx/domains/python.py`
  - Updated `PyMethod.get_index_text()` so entries for `py:method` with
    `:property:` omit `()` and match the formatting already used by
    `py:property`.
  - Made the `:property:` branch take precedence over callable method variants
    when selecting index text, so the presence of `:property:` consistently
    controls whether parentheses are shown.
  - Applied the same no-parentheses behavior to the unqualified/module-level
    fallback for consistency with `PyProperty.get_index_text()`.
- `reports/baseline_notes.md`
  - Added this notes file to document the root cause, changed files,
    assumptions, and alternatives considered for the benchmark task.

## Assumptions

- The issue is specifically about index entry text, not the rendered signature.
  The rendered signature already omits an argument list for `:property:`.
- A `py:method` directive with `:property:` should continue to register as the
  `method` object type for compatibility with existing cross-reference behavior.
- Reusing the existing property index formats is preferable because those
  translation strings already exist in this file.

## Alternatives considered

- Changing `py:method :property:` to register as object type `property` was
  rejected because it would affect domain inventory and cross-reference behavior,
  while the reported defect only concerns the index entry text.
- Adding a special case in the generic index-building code was rejected because
  the Python domain already owns object-specific index text formatting, and the
  incorrect `()` is local to `PyMethod.get_index_text()`.
