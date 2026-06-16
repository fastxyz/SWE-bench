# Baseline Notes

## Root cause

`_pytest.mark.expression.not_expr` converted every parsed identifier into
`ast.Name`. That included the reserved constant spellings `True`, `False`, and
`None`. On Python 3.8+ debug builds, CPython asserts in the compiler if a
manually constructed `ast.Name` uses one of those names, so
`Expression.compile("False")` aborted the interpreter instead of compiling the
match expression.

## Changed files

`repo/src/_pytest/compat.py`

Added `_ident_to_name`, a small AST compatibility helper. It preserves normal
identifier handling by returning `ast.Name` for all non-reserved names, but
emits a constant node for `True`, `False`, and `None`. The helper uses
`ast.Constant` on Python 3.8+ and `ast.NameConstant` on older supported Python
versions.

`repo/src/_pytest/mark/expression.py`

Changed marker expression AST construction to use `_ident_to_name` for the
empty expression fallback and for parsed identifiers. This prevents reserved
constant spellings from being emitted as invalid `ast.Name` nodes while keeping
all other identifiers routed through the matcher lookup.

## Assumptions and alternatives

I assumed the intended expression semantics should follow Python's treatment of
`True`, `False`, and `None` as constants, because those spellings cannot be
valid Python names and are rejected by the CPython compiler when represented as
`ast.Name` in debug builds.

I considered changing only the literal `"False"` case from the reproducer, but
rejected that because the same compiler assertion also covers `True` and `None`.

I considered leaving the helper local to `mark/expression.py`, but placed it in
`compat.py` because the fix is version-dependent AST construction and the
repository already centralizes Python-version compatibility helpers there.

I did not add or modify tests, and did not run tests or project code, per the
task constraints.
