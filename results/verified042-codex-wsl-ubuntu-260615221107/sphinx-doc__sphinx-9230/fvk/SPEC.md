# FVK Spec

Status: constructed specification for the V1 fix, not machine-checked.

## Target Units

- `repo/sphinx/util/docfields.py`: `DocFieldTransformer.transform()`, only the
  inline typed field branch for `TypedField` instances.
- `repo/sphinx/ext/autodoc/typehints.py`: `modify_field_list()` and
  `augment_descriptions_with_types()`, only the scanner logic that classifies
  `:param ...:` fields as documented and/or typed.

There are no loops in the audited slices.

## Human-Readable Contract

For a recognized typed doc field:

1. If the field argument contains exactly one whitespace-separated token, that
   token is the parameter name and no inline type is recorded.
2. If the field argument contains two or more whitespace-separated tokens, the
   final token is the parameter name and the preceding tokens, joined by the
   field text's whitespace, are the type expression.
3. The parameter description content is not changed by this split.
4. Existing separate `:type name:` fields continue to provide type content for
   the same `name`.
5. Autodoc type-hint merging uses the same final-token parameter-name rule when
   deciding whether a `:param type name:` field already documents and types an
   annotated parameter.

## Public Intent Ledger

The standalone ledger is `fvk/PUBLIC_EVIDENCE_LEDGER.md`; the critical entries
are mirrored here:

- E1-E3: the public issue gives `:param dict(str, str) opc_meta:` and requires
  name `opc_meta`, not `str) opc_meta`.
- E4: public tests require existing `:param str name:` behavior to remain.
- E5-E6: separate type fields already support container type expressions such as
  `Tuple[str, ...]` and `dict(str, int)`.
- E7: the older "single word" docs sentence is under-specific relative to the
  issue and does not override the bug report.
- E8: autodoc type-hint merging has parallel parameter-name interpretation and
  must not keep the legacy first-split association.
- E9: no tests or execution are allowed in this benchmark phase.

## Formal Abstraction

The K model abstracts a docfield argument as a non-empty list of whitespace
tokens:

- `word(S)` represents a one-token field argument.
- `words(PREFIX, LAST)` represents a token list with final token `LAST`.
- `joinWords(PREFIX)` reconstructs the type expression represented by all
  tokens before the final name token.

The modeled observable is intentionally narrow but property-complete for this
bug: it distinguishes the passing split
`inline("dict(str, str)", "opc_meta")` from the failing split
`inline("dict(str,", "str) opc_meta")`.

Formal files:

- `fvk/mini-docfield.k`
- `fvk/docfield-spec.k`

## Frame Conditions

- Field names and aliases are not changed.
- Function signatures are not changed.
- Existing one-token and single-word inline typed examples are preserved.
- Separate type-field behavior is not changed by the inline typed branch.
- No test files are modified.

## Out-of-Scope Inputs

- Parameter names containing whitespace.
- Domain-specific declarator parsing beyond the generic Sphinx
  `:param type name:` shape.
- Type-expression internal whitespace normalization.
