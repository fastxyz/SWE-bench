# FVK Proof

Status: constructed, not machine-checked. No commands in this file were executed.

## Contract

For every exact `# /// script` opening line, if the following valid embedded-content prefix contains
at least one content line equal to `///`, `skip_script_comments` selects the last such delimiter and
advances the comment iterator through that delimiter. `commented_out_code` then skips ERA001
analysis for the opening tag and the consumed metadata comments. If no delimiter exists, no
suppression occurs.

## Constructed Proof Sketch

PO1 follows directly from the unchanged exact equality check in `is_script_tag_start`.

PO2 follows by case analysis on `script_line_content`:

- no leading `#` gives `None`, modeled as `invalidContent()`;
- `#` alone gives `Some("")`, modeled as `content("")`;
- `# ` followed by text gives `Some(text)`, modeled as `content(text)`;
- `#` followed by any non-space character gives `None`.

PO3 is the central V1 change. Symbolically execute `scanFrom(lines, last)` over the valid prefix:

- on `content("///")`, the K rule rewrites the candidate from any `last` to `someInt(end)`;
- on `content(C)` where `C != "///"`, the candidate is preserved;
- on `invalidContent()` or `.Lines`, the scan returns the candidate.

By induction over the line sequence, the returned candidate is therefore exactly the last delimiter
full-end in the valid prefix, or `noneInt()` if none exists. This removes the pre-fix next-line
condition that made a valid block appear invalid when ordinary comments followed the delimiter.

PO4 follows by induction over the sorted comment iterator:

- if the next comment starts before `end_offset`, one iterator element is consumed and the proof
  repeats on the tail;
- if the next comment starts at or after `end_offset`, the iterator is unchanged and the skip loop
  stops.

PO5 composes PO3 and PO4 with the unchanged `continue` in `commented_out_code`: once the helper
returns `true`, the current opening tag is not checked for ERA001 and all consumed metadata comments
have already been removed from the iterator.

PO6 follows from the `noneInt()` scan result: source line 108 returns `false`, so the normal ERA001
path remains active for malformed script blocks.

PO7 follows by frame reasoning: V1 changes only delimiter selection inside `skip_script_comments`.
The existing `is_own_line_comment` and `comment_contains_code` path is unchanged for all comments
outside the selected skip range.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-era001-script-scan.k --backend haskell
kast --backend haskell fvk/era001-script-scan-spec.k
kprove fvk/era001-script-scan-spec.k
```

Expected result after a real K run: all claims discharge to `#Top`. This session did not run K, so
the proof remains constructed rather than machine-verified.

## Test Recommendation

Keep all tests. The session forbids execution and test edits, and the proof has not been
machine-checked. A useful public regression test after this session would cover a `# /// script`
block with TOML list metadata, a closing `# ///`, additional ordinary comments, and then Python
code; it should assert no ERA001 diagnostic on the metadata lines.

## Residual Risk

The proof is partial and scoped to delimiter selection plus iterator advancement. It does not prove
TOML validity, full PEP 723 parsing, Ruff's tokenization, `comment_contains_code`, or end-to-end CLI
diagnostic rendering.
