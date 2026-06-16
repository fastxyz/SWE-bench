# FVK Spec

Status: constructed from public evidence only; no tests, Ruff execution, Python execution, or K
tooling were run.

## Target

The audited unit is `ERA001` script-metadata suppression in
`repo/crates/ruff_linter/src/rules/eradicate/rules/commented_out_code.rs`:

- `commented_out_code`, especially the branch that calls `skip_script_comments`.
- `skip_script_comments`, the helper changed by V1.
- `script_line_content`, because it defines which lines are valid embedded-content lines.

## Intent Spec

For an exact `# /// script` opening line, `ERA001` must not report commented-out-code diagnostics
for valid PEP 723 inline script metadata comments. A metadata block is valid for this suppression
when scanning the following lines as PEP 723 embedded content finds at least one content line equal
to `///`; the selected closing delimiter is the last such line before the first invalid embedded
content line or EOF. If no delimiter is found, the block is invalid and normal `ERA001` analysis
continues. Non-script comments outside the skipped range remain governed by the existing
`comment_contains_code` path.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "ERA001 false positive inside inline script metadata with trailing additional comment" | `ERA001` diagnostics on metadata lines in a valid inline script block are false positives. | Encoded in PO1, PO3, PO5. |
| E2 | prompt | The repro shows `# dependencies = [` and `# ]` flagged between `# /// script` and `# ///`. | List-like TOML metadata lines inside the selected block must be skipped before `comment_contains_code`. | Encoded in PO5. |
| E3 | prompt | The repro has comments after the closing `# ///` before Python code. | Trailing comments must not make the preceding metadata block invalid. | Encoded in PO3. |
| E4 | source comment/parser | `ruff_python_ast::script` says the closing pragma is the last `///` line and then truncates lines after it. | Delimiter selection should be "last delimiter in the valid embedded-content prefix," not "first delimiter followed by an invalid next line." | Encoded in PO3. |
| E5 | existing source behavior | `commented_out_code` only applies script suppression when `is_script_tag_start(line)` is exactly `# /// script`. | Opening tag recognition is outside this issue and remains exact. | Encoded in PO1. |
| E6 | existing source behavior | `skip_script_comments` returns `false` when no `end_offset` exists. | Unclosed script blocks must not suppress `ERA001`. | Encoded in PO6. |

No hidden tests, upstream patches, benchmark results, or internet sources were used.

## Formal Model

The K artifacts are:

- `fvk/mini-era001-script-scan.k`: a minimal semantics for the changed scan and iterator-advance
  logic.
- `fvk/era001-script-scan-spec.k`: reachability claims for delimiter update, non-delimiter
  preservation, invalid-line stopping, unclosed-block behavior, and iterator advancement.

The model abstracts a source file after the opening tag into ordered `Line` values:

- `content(S)` means `script_line_content` returned `Some(S)`.
- `invalidContent()` means `script_line_content` returned `None`.
- `scanFrom(lines, last)` corresponds to the V1 `for line in lines` scan.
- `skipBefore(end, comments)` corresponds to the V1 `while comment.start() < end_offset` loop.

The abstraction preserves the property under audit: whether a delimiter is selected, which delimiter
is selected, and which comment ranges are skipped.

## Adequacy Audit

The formal claims are adequate for the public issue because they cover the behavior that produces
the reported false positives:

- The pre-fix failure requires `scanFrom` to reject a block when a delimiter is followed by another
  valid comment line. PO3 rejects that legacy condition by proving every delimiter overwrites the
  candidate close.
- The reported diagnostics require metadata comments to reach `comment_contains_code`. PO5 prevents
  that by advancing the iterator over comments before the selected close.
- The public issue does not require broad suppression of all comments after the selected delimiter.
  PO4 preserves V1's narrower frame condition: only comments whose start is before the delimiter's
  full end are skipped.

The spec does not prove full Ruff behavior, parsing, TOML validity, or `comment_contains_code`
accuracy. Those are outside the narrowed public issue and unchanged by V1.

## Compatibility Audit

V1 did not change public APIs, function signatures, exported types, rule codes, diagnostic messages,
or settings. It removed one private helper that became unnecessary after the iterator no longer
peeks ahead. Public compatibility finding: no public callsite or override update is required.
