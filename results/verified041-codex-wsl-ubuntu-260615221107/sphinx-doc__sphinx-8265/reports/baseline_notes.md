# Baseline Notes

## Root Cause

Autodoc emits callable signatures as Python-domain directives, and the Python
domain reparses the argument list with `sphinx.util.inspect.signature_from_str()`.
That helper builds an AST and stores each default value as an unparsed string.
The shared AST unparser intentionally renders a non-empty tuple expression
without surrounding parentheses, so a default such as `(1, 1, 1)` became the
string `1, 1, 1`. The Python domain then rendered that string as the default
value node, producing `color=1, 1, 1` in HTML.

## Files Changed

`repo/sphinx/pycode/ast.py`

Added `unparse_default()`, a default-value-specific AST unparse path. It keeps
the existing `unparse()` behavior intact, but enables tuple parenthesizing when
an expression is being rendered as a default value. This preserves tuple
defaults, including single-element and nested tuples, while still avoiding
extra parentheses in subscript slices such as `Tuple[int, int]`.

`repo/sphinx/util/inspect.py`

Changed `signature_from_ast()` to use `unparse_default()` for positional,
positional-only, and keyword-only default values. Annotations and return
annotations continue to use the original `ast_unparse()` path.

## Assumptions

The reported broken HTML comes from the normal autodoc-to-Python-domain
signature path rather than from the HTML writer. The writer receives already
split signature nodes, so preserving the default string during signature parsing
is the targeted fix.

Tuple parenthesizing is only required in expression/default contexts. Existing
annotation rendering depends on tuple AST nodes inside subscript slices staying
unparenthesized, for example `Tuple[int, int]`.

I did not run tests or project code because the benchmark instructions state
that this session has no execution environment and explicitly forbid running
tests or code.

## Alternatives Considered

Changing `visit_Tuple()` globally was rejected because existing unparse behavior
and type annotation formatting rely on non-empty tuples being emitted without
parentheses in some contexts.

Changing the HTML writer or parameter-list writer was rejected because the
incorrect text is introduced earlier, when AST defaults are converted to strings
inside `signature_from_ast()`.

Falling back to the pseudo argument parser was rejected because it splits on
commas and would not correctly handle tuple defaults.
