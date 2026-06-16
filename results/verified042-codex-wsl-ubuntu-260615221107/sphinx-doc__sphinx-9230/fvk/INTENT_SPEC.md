# Intent Spec

Status: intent-first specification, derived from public issue text, in-repo docs,
and public tests.  Current implementation behavior is treated as observed
candidate behavior, not as the specification.

## In-Scope Behavior

I1. For an inline typed parameter field of the form
`:param dict(str, str) opc_meta:`, the rendered parameter name must be
`opc_meta`, and the rendered type must be the whole container expression
`dict(str, str)` modulo Sphinx's existing type-node rendering.  The legacy
split `str) opc_meta (dict(str,)` is explicitly the reported bug.

I2. Existing inline single-word typed fields such as `:param str name:` must
continue to render as parameter `name` with type `str`.

I3. Existing separate type-field behavior such as `:param items:` plus
`:type items: Tuple[str, ...]` must remain unchanged.

I4. For autodoc type-hint description merging, a documented inline typed
parameter must be associated with the actual parameter name, so annotations for
`opc_meta` are not duplicated or attached to `str) opc_meta`.

I5. The patch must not change public function signatures, directive field names,
node shapes beyond the corrected parameter/type split, or test files.

## Domain

D1. For inline typed fields whose field argument contains two or more
whitespace-separated tokens, the final token is the parameter name and all
preceding tokens form the type expression.

D2. For field arguments with one token, there is no inline type expression;
the token is the parameter name.

D3. Parameter names containing whitespace are outside the intended Python
parameter-field domain.  Domain-specific declarator syntax beyond the observed
Sphinx `:param type name:` convention is not specified here.

## Non-Goals and Ambiguities

A1. The public issue's expected text omits the space after the comma in
`dict(str,str)`, while the input includes `dict(str, str)`.  Existing Sphinx
type rendering preserves punctuation and spacing in type expressions such as
`Tuple[str, ...]`; this audit treats exact internal whitespace normalization as
out of scope.  The required property is the type/name boundary.

A2. The existing user docs say combined parameter type and description are
possible when the type is a single word.  The issue supplies newer positive
intent for a container type expression with internal whitespace, so that docs
line is treated as under-specifying older behavior, not as an obligation to
preserve the bug.
