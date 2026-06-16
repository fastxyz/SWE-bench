# Baseline Notes

## Root cause

`sympy.codegen.ast.String` stored its public `text` attribute outside of
`Basic.args` by listing `text` in `not_in_args`. That kept the raw Python
string out of the `Basic` argument tuple, but it also made `String('x').args`
empty. As a result, the normal `Basic` reconstruction invariant
`expr.func(*expr.args) == expr` could not hold for `String`.

## Changed files

`repo/sympy/codegen/ast.py`

- Imported `Str`, SymPy's `Basic` wrapper for textual data.
- Updated `String.__new__` so `String.text` remains a Python `str`, while
  `String.args` contains `Str(text)`. This keeps all arguments as `Basic`
  instances and lets `String(Str(text))` reconstruct the original object.
- Updated `String._construct_text` to accept `Str` during reconstruction from
  `.args`.
- Added a `Token.atoms()` override for default atom collection so codegen
  `String` remains an atomic leaf even though its reconstruction argument is now
  represented internally by `Str`.

## Assumptions and alternatives

I assumed the fix should preserve both SymPy's `Basic` argument convention and
the existing codegen API where `String.text` is a Python string.

I considered putting the raw Python string directly in `String.args`, but
rejected that because `Basic.args` entries are expected to be `Basic` objects.

I considered changing global `Basic.atoms()` to treat all `is_Atom` objects as
leaves, but rejected that as broader than necessary because other SymPy classes
set `is_Atom` while still carrying meaningful arguments. The atom-preservation
logic is scoped to codegen `Token` objects instead.
