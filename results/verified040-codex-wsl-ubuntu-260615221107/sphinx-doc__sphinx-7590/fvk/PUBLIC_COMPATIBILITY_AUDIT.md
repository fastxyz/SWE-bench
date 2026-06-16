# Public Compatibility Audit

Status: no public API or dispatch signature changes.

## Changed Symbols

- `DefinitionParser._parse_string(self) -> str`
  - Compatibility: private parser helper; signature unchanged.
  - Callers: `_parse_literal()` only in the same class.
  - Result shape: still returns the literal spelling string or `None`.
  - Change: recognizes prefixed and raw C++ string literal spellings before
    suffix attachment.

- `DefinitionParser._parse_literal(self) -> ASTLiteral`
  - Compatibility: private parser helper; signature unchanged.
  - Callers: existing expression parser paths.
  - Result shape: still returns `ASTLiteral` or `None`; suffixed literals now
    return `ASTUserDefinedLiteral`, a subclass of `ASTLiteral`.

- `ASTUserDefinedLiteral`
  - Compatibility: new internal AST node only.
  - Public behavior: `str()` and `describe_signature()` preserve literal
    spelling, including suffix.

## Unchanged Public Surfaces

- No directive signatures changed.
- No Sphinx configuration names changed.
- No C-domain files changed.
- No test files changed.
- `operator""` declaration parsing remains in `_parse_operator()` and was not
  edited.
