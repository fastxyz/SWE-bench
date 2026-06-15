# Formal Spec in English

Status: constructed, not machine-checked.

## `ALLOW-DEFAULT-KWONLY`

If `parse_bits()` sees a keyword token whose name is in the callable's complete
keyword-only parameter list, and that name has not already been supplied, then
the token is legal even when the parameter has a default and is absent from the
required-keyword-only list. Parsing records the keyword rather than raising an
unexpected-keyword error.

## `DUPLICATE-KWONLY`

If `parse_bits()` sees two keyword tokens with the same keyword-only parameter
name, the first token records the keyword and the second token raises the
existing multiple-values `TemplateSyntaxError`.

## `UNKNOWN-STILL-UNEXPECTED`

If `parse_bits()` sees a keyword token whose name is neither a positional
parameter nor a keyword-only parameter, and the callable has no `**kwargs`,
parsing raises the existing unexpected-keyword `TemplateSyntaxError`.

## `MISSING-REQUIRED-KWONLY`

If a keyword-only parameter has no default and no keyword token supplies it,
that name remains in the required-keyword-only remainder and the final
missing-argument `TemplateSyntaxError` is raised.

## Compatibility Claim

Because the public call signatures and return shape are unchanged, and because
`simple_tag()` and `inclusion_tag()` both delegate to `parse_bits()`, the proven
helper behavior applies to both tag helpers named by the issue.
