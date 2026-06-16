# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Exact Opening Tag Gate

Claim: script suppression is attempted only when the current own-line comment is exactly
`# /// script`.

Evidence: `is_script_tag_start(line) -> line == "# /// script"`.

Purpose: prevent the fix from broadening ERA001 suppression to unrelated comments.

Discharged by: unchanged V1 source and frame reasoning.

## PO2 - Embedded Content Classification

Claim: `script_line_content` maps a line to embedded content exactly when it starts with `#` and,
if any character follows `#`, that next character is a space. `#` maps to empty content.

Evidence: `script_line_content` source and matching parser comments in `ruff_python_ast::script`.

Purpose: define the valid prefix scanned by PO3.

Discharged by: unchanged V1 source and the K `Content` abstraction.

## PO3 - Last Delimiter Selection

Claim: while scanning the valid embedded-content prefix after `# /// script`, every content line
equal to `///` becomes the current close candidate. At the first invalid line or EOF, the selected
close is the last delimiter seen. A valid comment line after a delimiter does not invalidate the
candidate.

Evidence: public parser uses the last `///` line as closing pragma; the issue has ordinary comments
after the delimiter.

Discharged by: V1 lines 95-104 and K claims in `era001-script-scan-spec.k` for delimiter update,
non-delimiter preservation, invalid-line stopping, and EOF.

## PO4 - Iterator Advancement Boundary

Claim: on a valid block, the comments iterator advances exactly while `comment.start() < end_offset`
and stops at the first comment whose start is at or after the selected delimiter's full end.

Evidence: V1 lines 112-119.

Purpose: skip metadata comments while preserving normal ERA001 analysis outside the selected range.

Discharged by: K `skipBefore` claims.

## PO5 - No ERA001 Diagnostics for Skipped Metadata

Claim: if `skip_script_comments` returns `true`, `commented_out_code` immediately continues the
outer loop, so the opening tag and consumed metadata comments do not reach `comment_contains_code`.

Evidence: V1 lines 60-63.

Purpose: directly rules out the reported diagnostics on `# dependencies = [` and `# ]`.

Discharged by: composition of PO3, PO4, and the unchanged `continue`.

## PO6 - Unclosed Block Preservation

Claim: if no delimiter is found in the valid embedded-content prefix, `skip_script_comments`
returns `false` and normal ERA001 analysis continues.

Evidence: V1 lines 107-110 and existing source comment "Unclosed blocks MUST be ignored."

Purpose: avoid suppressing diagnostics for malformed script-tag-like comments.

Discharged by: K `scanFrom(.Lines, noneInt()) => noneInt()` claim and source inspection.

## PO7 - Non-Script ERA001 Frame

Claim: comments that do not pass PO1, or that remain after PO4 stops, are handled by the existing
own-line/comment-code path.

Evidence: unchanged V1 lines 66-72.

Purpose: preserve the rule's ordinary behavior outside the issue's inline-script metadata block.

Discharged by: frame reasoning over unchanged source.

## PO8 - Honesty Gate

Claim: no test, Ruff, Python, or K result is asserted. The proof is constructed only.

Evidence: task constraints and `PROOF.md` commands section.

Purpose: prevent hidden-test or execution-result inference.

Discharged by: this artifact set and `reports/fvk_notes.md`.
