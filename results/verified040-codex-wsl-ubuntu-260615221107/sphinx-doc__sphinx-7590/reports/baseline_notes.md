# Baseline Notes

## Root Cause

The C++ domain parser recognized ordinary numeric, string, and character literals,
but it did not consume a user-defined literal suffix after the core literal token.
For the reported initializer, `6.62607015e-34q_J * 1q_s`, parsing stopped after
`6.62607015e-34` and left `q_J` in the input stream. The expression parser then
reported unexpected trailing text before reaching the `*` operator.

## Changed Files

`repo/sphinx/domains/cpp.py`

- Added a small user-defined literal suffix regex for C++ literal parsing.
- Added `ASTUserDefinedLiteral`, a wrapper that preserves the behavior of the
  existing literal AST nodes while appending the parsed suffix when rendering or
  deriving an id.
- Updated `_parse_literal()` to attach an immediate suffix to numeric, string,
  and character literals. Numeric literals still keep the existing built-in
  suffix handling before checking for a user-defined suffix.

## Assumptions

- The issue concerns C++ literal expressions, not declarations of literal
  operators. Operator declarations such as `operator""_udl` were already parsed
  by `_parse_operator()`.
- The suffix grammar supported here is the ASCII identifier form already used by
  the parser for ordinary C++ identifiers. More exotic suffix spellings such as
  universal-character-name escapes are outside the parser's current identifier
  support and were not added.
- The C domain was left unchanged because C does not have C++ user-defined
  literals, even though it shares similar numeric literal parsing code.

## Alternatives Considered

- Extending the common literal regexes in `sphinx.util.cfamily` was rejected
  because those regexes are shared with the C domain and would make C accept a
  C++-only feature.
- Storing the suffix directly inside each existing literal class was rejected for
  character literals because `ASTCharLiteral` decodes its literal body; appending
  a suffix there would mix token spelling with character data. A wrapper keeps
  the suffix separate and preserves existing literal behavior.
