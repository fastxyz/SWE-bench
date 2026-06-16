# Baseline Notes

## Root Cause

`ERA001` has a local PEP 723 script metadata scanner in
`crates/ruff_linter/src/rules/eradicate/rules/commented_out_code.rs`. The scanner only treated a
`# ///` line as the closing delimiter when the immediately following line was not another valid
embedded metadata comment line.

That differs from Ruff's shared script metadata parser in `ruff_python_ast::script`, which treats
the last `# ///` line before non-metadata content as the closing delimiter. As a result, an inline
script metadata block followed by ordinary comments was considered invalid by `ERA001`, so the rule
continued checking the metadata lines and flagged list-like TOML as commented-out Python code.

## Changed Files

- `repo/crates/ruff_linter/src/rules/eradicate/rules/commented_out_code.rs`: changed
  `skip_script_comments` to scan valid script metadata comment lines and remember the latest
  `# ///` delimiter before the block stops. If such a delimiter exists, the rule skips comments
  through that delimiter. This keeps `ERA001` from checking valid inline script metadata while still
  treating blocks with no delimiter as invalid.

## Assumptions

- A PEP 723 metadata block should be considered valid for `ERA001` when it has at least one closing
  `# ///` delimiter after `# /// script`, even if additional ordinary comments appear before the next
  Python code line.
- Comments after the closing delimiter are not part of the metadata block for lint suppression
  purposes; the change skips through the selected closing delimiter only.
- The exact start tag behavior, `# /// script`, should remain unchanged because the issue is about
  closing-block detection, not discovering script blocks.

## Alternatives Considered

- Skipping every comment after `# /// script` until the first non-comment line would avoid this false
  positive, but it would also suppress `ERA001` on ordinary comments after the metadata block.
- Calling the shared `ScriptTag::parse` helper directly would align validity with the parser, but it
  does not expose the closing delimiter range needed by `ERA001` to advance the comment iterator.
- Special-casing list syntax like `# dependencies = [` and `# ]` would fix the shown example only,
  but the underlying bug is block-boundary handling for inline script metadata.
