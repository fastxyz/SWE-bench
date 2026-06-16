# Proof Obligations

Status: constructed, not machine-checked.

## PO-NUM-1: Numeric UDL Consumption

- Claim: if a recognized numeric literal core is immediately followed by a valid
  UDL suffix, `_parse_literal()` returns a literal whose spelling is
  `core + suffix` and leaves the following input untouched.
- Evidence: E1, E2, E3.
- Source discharge: numeric path creates `ASTNumberLiteral(core)` and passes it
  to `_parse_user_defined_literal()`, which consumes `_udl_suffix_re` and wraps
  the base literal.
- K claim: `UDL-NUMERIC` in `cpp-udl-spec.k`.

## PO-NUM-2: Numeric No-Suffix Frame

- Claim: if a numeric literal has no immediate valid suffix, existing numeric
  literal behavior is preserved, including existing built-in suffix scanning.
- Evidence: existing parser behavior and compatibility intent.
- Source discharge: `_parse_user_defined_literal()` returns the original literal
  when `_parse_user_defined_literal_suffix()` returns `None`.
- K claim: `NO-SUFFIX-FRAME`.

## PO-STR-1: Ordinary And Prefixed String UDL Consumption

- Claim: ordinary and encoding-prefixed string literals can carry an immediate
  valid UDL suffix.
- Evidence: E1, E3, E5.
- Source discharge: `_parse_string()` now preserves the prefix in the returned
  string core, and `_parse_literal()` attaches a suffix through the same wrapper
  helper.
- K claim: `UDL-STRING`.

## PO-STR-2: Raw String UDL Consumption

- Claim: raw string literal spelling can carry an immediate valid UDL suffix.
- Evidence: E1, E5.
- Source discharge: `_parse_string()` scans from `R"` through the matching raw
  string terminator and returns the whole raw string core before suffix
  attachment.
- K claim: `UDL-STRING`.

## PO-CHAR-1: Character UDL Consumption

- Claim: recognized character literals can carry an immediate valid UDL suffix
  without changing character decoding.
- Evidence: E1, E3, E5.
- Source discharge: `_parse_literal()` constructs `ASTCharLiteral` first, then
  wraps it with `ASTUserDefinedLiteral` if a suffix is present.
- K claim: `UDL-CHAR`.

## PO-RENDER-1: Rendered Spelling Preservation

- Claim: `str(literal)` and `describe_signature()` preserve the original literal
  spelling plus suffix.
- Evidence: issue requires a valid declaration signature, and Sphinx signatures
  must display parsed declarations.
- Source discharge: `ASTUserDefinedLiteral._stringify()` returns
  `transform(self.literal) + self.suffix`; `describe_signature()` delegates to
  the base literal and appends the suffix as text.
- K claim: represented by the `parsed(kind, core +String suffix, suffix, rest)`
  postcondition.

## PO-FRAME-1: C Domain Frame

- Claim: C literal parsing is unchanged.
- Evidence: E6.
- Source discharge: only `repo/sphinx/domains/cpp.py` is edited; shared
  `sphinx.util.cfamily` regexes and `repo/sphinx/domains/c.py` are untouched.

## PO-FRAME-2: Literal Operator Declaration Frame

- Claim: `operator""` declaration parsing remains unchanged.
- Evidence: E4.
- Source discharge: `_parse_operator()` is untouched.

## PO-SCOPE-1: Suffix Scope Limitation

- Claim: the implementation covers suffixes in the parser's ASCII identifier
  scope.
- Evidence: existing parser identifier support.
- Status: accepted limitation and residual finding F5.

## Machine-Check Commands

Not executed in this session:

```sh
kompile fvk/mini-cpp-literals.k --backend haskell
kast --backend haskell fvk/cpp-udl-spec.k
kprove fvk/cpp-udl-spec.k
```

Expected machine-check result: `#Top` for the four claims in
`cpp-udl-spec.k`.
