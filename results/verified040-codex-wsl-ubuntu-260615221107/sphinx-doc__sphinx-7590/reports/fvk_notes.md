# FVK Notes

## Summary

The FVK audit confirmed V1's core fix for the reported numeric user-defined
literal failure, but found one completeness gap: V1 attached suffixes after
ordinary string literals only when the current character was `"`, so prefixed
and raw C++ string literal spellings were still outside the parser path. V2 keeps
the V1 suffix wrapper design and extends `_parse_string()` to recognize
encoding-prefixed and raw string cores before suffix attachment.

## Decisions Traced To FVK Artifacts

### Keep V1 numeric suffix handling

- Findings: `fvk/FINDINGS.md` F1.
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO-NUM-1 and PO-NUM-2.
- Decision: keep `_udl_suffix_re`, `_parse_user_defined_literal_suffix()`, and
  `_parse_user_defined_literal()`.
- Reason: the reported failure occurs because the numeric parser consumed only
  `6.62607015e-34` and left `q_J`; the helper now consumes the immediate suffix
  and leaves parsing positioned at the following operator.

### Keep the wrapper AST node

- Findings: F1 and F3.
- Proof obligations: PO-NUM-1, PO-CHAR-1, and PO-RENDER-1.
- Decision: keep `ASTUserDefinedLiteral`.
- Reason: the wrapper preserves existing number/string/character AST behavior
  while appending the suffix for rendering and signature output. This is
  especially important for character literals because `ASTCharLiteral` decodes
  only the character body.

### Improve string literal recognition

- Findings: F2.
- Proof obligations: PO-STR-1 and PO-STR-2.
- Decision: revise `_parse_string()` so it recognizes optional `u8`, `u`, `U`,
  and `L` prefixes, and raw string spelling, before returning the string core.
- Reason: "C++ user-defined literals" is a family obligation, not just the
  reported floating-literal instance. V1 covered `"m"_tag` but not
  `u8"m"_tag` or `R"(m)"_tag`.

### Leave shared C-family regexes and C parser unchanged

- Findings: F4.
- Proof obligations: PO-FRAME-1.
- Decision: do not edit `sphinx.util.cfamily` or `repo/sphinx/domains/c.py`.
- Reason: UDL suffixes are C++-specific; moving suffix recognition into shared
  literal regexes would leak C++ syntax into the C domain.

### Leave literal operator declarations unchanged

- Findings/evidence: public evidence ledger E4.
- Proof obligations: PO-FRAME-2.
- Decision: do not edit `_parse_operator()`.
- Reason: `operator""` declarations already have a parser path; the issue is
  expression literals with suffixes.

### Accept bounded suffix scope

- Findings: F5.
- Proof obligations: PO-SCOPE-1.
- Decision: keep suffix matching to `[A-Za-z_][A-Za-z0-9_]*`.
- Reason: this matches the parser's existing ASCII-oriented identifier support.
  Universal-character-name suffix spelling remains an explicit limitation rather
  than a hidden assumption.

## Verification Status

The FVK proof is constructed, not machine-checked. Per the task constraints, I
did not run tests, Python, `kompile`, `kast`, or `kprove`. The exact K commands
to run later are recorded in `fvk/PROOF.md` and
`fvk/PROOF_OBLIGATIONS.md`.
