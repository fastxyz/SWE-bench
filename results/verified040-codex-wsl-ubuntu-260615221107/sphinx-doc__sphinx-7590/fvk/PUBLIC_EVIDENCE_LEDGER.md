# Public Evidence Ledger

## E1

- Source: prompt / issue
- Evidence: "C++ User Defined Literals not supported"
- Obligation: C++ user-defined literal expressions are in scope.
- Status: encoded in `SPEC.md`, `PROOF_OBLIGATIONS.md`, and
  `cpp-udl-spec.k`.

## E2

- Source: prompt / issue
- Evidence: `6.62607015e-34q_J * 1q_s` produces "Expected end of definition"
  with the caret at `q_J`.
- Obligation: after recognizing the floating literal core
  `6.62607015e-34`, the parser must consume `q_J` as a literal suffix and
  continue parsing at `*`; similarly `1q_s` must consume `q_s`.
- Status: resolved by finding F1 / proof obligation PO-NUM-1.

## E3

- Source: source code comment
- Evidence: `_parse_literal()` lists `user-defined-literal` and V1 removed the
  previous `TODO`.
- Obligation: the expression literal parser, not only literal operator
  declarations, must cover suffixed literals.
- Status: encoded by PO-NUM-1, PO-STR-1, and PO-CHAR-1.

## E4

- Source: source code
- Evidence: `_parse_operator()` already handles `operator""` suffixes.
- Obligation: keep operator declaration parsing unchanged; the missing behavior
  is literal expression parsing.
- Status: encoded by PO-FRAME-2.

## E5

- Source: default C++ domain assumption and parser structure
- Evidence: C++ user-defined literals are a family over numeric, string, and
  character literal spellings; `char_literal_re` already supports character
  prefixes and `_parse_string()` is the string literal recognizer.
- Obligation: do not stop at only the issue's floating literal example; cover
  string and character literal suffixes too. V1 covered unprefixed strings but
  not prefixed/raw string spelling.
- Status: V2 source change; finding F2; obligations PO-STR-1 and PO-STR-2.

## E6

- Source: source code organization
- Evidence: C and C++ domains share `sphinx.util.cfamily` literal regexes, but
  user-defined literals are C++-specific.
- Obligation: do not add UDL suffix matching to the shared C-family regexes.
- Status: encoded by PO-FRAME-1.
