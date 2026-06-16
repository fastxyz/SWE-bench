# Baseline Notes

## Root cause

The doc field transformer parsed inline typed fields such as `:param type name:`
with `fieldarg.split(None, 1)`.  For `:param dict(str, str) opc_meta:`, that
split treats the first space inside the type expression as the boundary between
type and parameter name, producing type `dict(str,` and parameter name
`str) opc_meta`.  The rendered output then shows the wrong parameter name and a
truncated type.

## Files changed

`repo/sphinx/util/docfields.py`

- Changed inline typed field parsing to split from the right with
  `fieldarg.rsplit(None, 1)`.
- This keeps existing `:param str name:` behavior while allowing whitespace
  inside the type expression, so `dict(str, str) opc_meta` is interpreted as
  type `dict(str, str)` and name `opc_meta`.

`repo/sphinx/ext/autodoc/typehints.py`

- Updated autodoc's type-hint field scanner to identify the parameter name as
  the last token when it sees inline typed `:param type name:` fields.
- This keeps autodoc's annotation-merging logic consistent with the doc field
  renderer, preventing it from treating `str) opc_meta` as the documented
  parameter name for fields like `:param dict(str, str) opc_meta:`.
- Removed the now-unused `re` import after replacing `re.split(' +', ...)` with
  `str.split()`.

## Assumptions and alternatives

- I assumed inline typed parameter fields should support type expressions with
  internal spaces, matching the issue's expected rendering and the existing
  support for container type expressions in separate `:type:` fields.
- I assumed Python parameter names are represented by the final whitespace
  separated token in inline typed fields.  That matches the documented
  `:param type name:` shape and normal Python parameter naming.
- I considered restricting the change to `sphinx/util/docfields.py` only, but
  rejected that because autodoc's type-hint merger has parallel parsing for the
  same field syntax and would continue to associate annotations with the wrong
  parameter name.
- I did not update tests or documentation because test files are fixed for this
  benchmark and the requested fix is a minimal source change.
