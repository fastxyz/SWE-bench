# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and constructed proof obligations only.

## F1: Reported Numeric UDL Suffix Was Left As Trailing Input

- Classification: code bug, resolved by V1 and retained in V2.
- Evidence: issue example `6.62607015e-34q_J * 1q_s` failed at `q_J`.
- Observed before fix: `_parse_literal()` matched only `6.62607015e-34` as a
  floating literal, returned `ASTNumberLiteral`, and left `q_J` for the outer
  expression parser.
- Expected: `q_J` is consumed as an immediate UDL suffix, and parsing resumes at
  the `*` operator; `q_s` is likewise consumed after `1`.
- Proof obligation: PO-NUM-1.
- Source status: resolved by `_parse_user_defined_literal()` and
  `ASTUserDefinedLiteral`.

## F2: V1 Under-Covered String UDL Spellings

- Classification: code bug in V1, resolved in V2.
- Evidence: public intent says "C++ User Defined Literals", and C++ string
  literal spellings include ordinary, encoding-prefixed, and raw forms. V1 only
  attached suffixes after strings that started directly with `"`.
- V1 observed behavior by inspection: `u8"m"_tag` and `R"(m)"_tag` would not
  enter `_parse_string()` because the current character was `u` or `R`, not `"`.
- Expected: the string literal core is recognized, the suffix is attached, and
  the remaining input starts after the suffix.
- Proof obligations: PO-STR-1 and PO-STR-2.
- Source status: resolved by extending `_parse_string()` to handle `u8`, `u`,
  `U`, `L`, and raw string spelling before suffix attachment.

## F3: Character UDL Needs Suffix Attachment Without Re-Decoding The Suffix

- Classification: potential code bug avoided by the wrapper design.
- Evidence: `ASTCharLiteral` decodes the character body and rejects unsupported
  multi-character data.
- V1/V2 design: suffixes are represented by `ASTUserDefinedLiteral` rather than
  appended to `ASTCharLiteral.data`, so character decoding remains about the
  character core only.
- Expected: `'x'_tag` renders as `'x'_tag`, while `ASTCharLiteral` still sees
  only `x`.
- Proof obligation: PO-CHAR-1.
- Source status: resolved.

## F4: Shared C-Family Regex Change Would Leak C++ Syntax Into C

- Classification: compatibility risk avoided.
- Evidence: numeric literal regexes are imported from `sphinx.util.cfamily` by
  both C and C++ domains.
- Expected: C++ UDL suffix support should live in `sphinx.domains.cpp`, not in
  shared C regexes.
- Proof obligation: PO-FRAME-1.
- Source status: resolved by keeping `_udl_suffix_re` and suffix attachment in
  `cpp.py`.

## F5: Residual Suffix Character Scope

- Classification: underspecified intent / bounded parser scope.
- Evidence: the existing parser's identifier support is ASCII-oriented.
- Observed/expected: suffixes using universal-character-name escapes or other
  identifier spellings outside `[A-Za-z_][A-Za-z0-9_]*` are not modeled or
  implemented by this pass.
- Proof obligation: PO-SCOPE-1.
- Source status: open limitation, not used to justify accepting the reported
  failure.

## Proof-Derived Findings From `/verify`

- The constructed proof has no loop or recursion obligations.
- The main adequacy risk is abstraction: the mini K semantics models the literal
  transition rather than executing Python. The abstraction is sufficient for the
  reported defect because it keeps the two observables that distinguish pass from
  fail: rendered literal spelling and remaining input.
- Test removal is not recommended because no tests were machine-checked and the
  task forbids modifying test files.
