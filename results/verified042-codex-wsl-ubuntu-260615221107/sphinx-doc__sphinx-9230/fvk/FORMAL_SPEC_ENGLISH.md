# Formal Spec English

Status: paraphrase of `fvk/docfield-spec.k`.

C1. For every token list with at least two tokens, `parseInline` returns an
inline typed split whose parameter name is the final token and whose type is all
preceding tokens joined as the type expression.

C2. For the concrete issue tokenization `dict(str,` `str)` `opc_meta`,
`parseInline` returns type `dict(str, str)` and name `opc_meta`.

C3. For the existing public single-word example `str` `name`, `parseInline`
returns type `str` and name `name`.

C4. For a one-token field argument `name`, `parseInline` returns no inline type
and parameter name `name`.

C5. For every token list with at least two tokens, autodoc's abstract
`scanParam` says the parameter has a description, has a type, and is associated
with the final token as the parameter name.

C6. For the concrete issue tokenization, autodoc's abstract `scanParam`
associates the documented typed parameter with `opc_meta`.

No loop circularities are present.
