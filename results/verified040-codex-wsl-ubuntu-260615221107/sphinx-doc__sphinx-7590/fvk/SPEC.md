# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the C++ domain literal-expression parser affected by the
issue:

- `repo/sphinx/domains/cpp.py`: `DefinitionParser._parse_literal()`
- `repo/sphinx/domains/cpp.py`: `DefinitionParser._parse_string()`
- new internal node `ASTUserDefinedLiteral`

The modeled behavior is the parser-state transition after the ordinary literal
core has been recognized: whether an immediate user-defined suffix is consumed,
how the AST renders, and what input remains for the rest of expression parsing.

## Intent Summary

See `INTENT_SPEC.md` and `PUBLIC_EVIDENCE_LEDGER.md` for the intent-first
ledger. The key obligations are:

1. Parse the reported numeric UDL expression
   `6.62607015e-34q_J * 1q_s` without leaving `q_J` or `q_s` as stray
   identifiers.
2. Treat user-defined suffixes as part of literal expressions, not as separate
   id-expressions.
3. Cover the C++ UDL literal family: numeric, string, and character literals.
4. Preserve existing no-suffix literal behavior.
5. Avoid adding C++-only behavior to the shared C-family literal regexes or the
   C domain.

## Public Evidence Ledger

The ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1: The issue title says C++ user-defined literals are not supported.
- E2: The issue example fails at `q_J`, proving that numeric suffix consumption
  is the immediate bug.
- E3: `_parse_literal()` already lists `user-defined-literal`, making the missing
  implementation a self-declared parser gap.
- E4: `operator""` declarations already have a separate parser path.
- E5: C++ UDLs are a family over numeric, string, and character literal spellings.
- E6: The shared C-family regexes must not be changed for a C++-only feature.

## Formal Contract

Let `core` be a recognized C++ literal core, `suffix` be an immediate valid UDL
suffix matching `[A-Za-z_][A-Za-z0-9_]*`, and `rest` be the input following the
suffix.

### Numeric UDL

Precondition: `core` is a numeric literal recognized by the existing numeric
literal regex path.

Postcondition: parsing yields an `ASTUserDefinedLiteral(ASTNumberLiteral(core),
suffix)` whose string/signature spelling is `core + suffix`, and the parser
position advances to `rest`.

### String UDL

Precondition: `core` is a C++ string literal spelling recognized by
`_parse_string()`, including ordinary, encoding-prefixed, and raw forms.

Postcondition: parsing yields an `ASTUserDefinedLiteral(ASTStringLiteral(core),
suffix)` whose string/signature spelling is `core + suffix`, and the parser
position advances to `rest`.

### Character UDL

Precondition: `core` is a character literal recognized by `char_literal_re`.

Postcondition: parsing yields an `ASTUserDefinedLiteral(ASTCharLiteral(...),
suffix)` whose string/signature spelling is `core + suffix`, and the parser
position advances to `rest`.

### No-Suffix Frame

If no immediate valid suffix exists, numeric, string, and character literal
parsing returns the same literal AST shape as before this fix, except for the
intended additional recognition of prefixed/raw string cores.

## Formal Core

The constructed K artifacts are:

- `mini-cpp-literals.k`
- `cpp-udl-spec.k`

They abstract the Python implementation to a minimal literal parser transition:
`parse(kind, core, suffix, rest)`. The abstraction is property-complete for this
bug because the observable includes both the rendered literal spelling and the
remaining input. A failing pre-fix parser maps the reported example to a state
where the suffix remains in `rest`; the fixed parser maps it to a state where
the suffix is attached to the literal and `rest` starts at the following
operator.

Exact commands, not executed:

```sh
kompile fvk/mini-cpp-literals.k --backend haskell
kast --backend haskell fvk/cpp-udl-spec.k
kprove fvk/cpp-udl-spec.k
```

Expected result if the constructed artifacts and semantics are accepted by K:
`#Top` for all claims.

## Adequacy

The English paraphrase of the formal claims is in `FORMAL_SPEC_ENGLISH.md`.
`SPEC_AUDIT.md` marks each formal claim as passing against the intent spec.
`PUBLIC_COMPATIBILITY_AUDIT.md` records that no public API signatures or test
files changed.
