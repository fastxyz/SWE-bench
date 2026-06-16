# FVK Notes

## Decision summary

The FVK audit did not confirm V1 unchanged. It confirmed V1's parenthesis-balancing approach for the reported issue, but found a related empty-spread separator bug in the same fixer. I applied a V2 source patch.

## Trace to findings and proof obligations

- `FVK-F1` maps to `PO1`, `PO2`, and `PO3`. V1 already addressed the reported leftover `)` by counting opening parentheses between `**` and `{` and deleting the same number of closing `)` tokens after the inner `}`. V2 keeps that strategy.
- `FVK-F2` maps to `PO4`, `PO5`, and `PO6`. V1 treated empty spreads like a wrapper-only deletion, which can leave `{, "x": 1}` or `{"x": 1, , "y": 2}`. V2 changes the empty branch to remove the empty spread as a dict item and choose the correct adjacent comma by position.
- `FVK-F3` applies to all proof obligations. I did not run tests, Python, Ruff, Cargo, `kompile`, or `kprove`; the proof is constructed only.

## Source changes

Changed `repo/crates/ruff_linter/src/rules/flake8_pie/rules/unnecessary_spread.rs`:

- `unnecessary_spread` now passes whether the current spread item is first or last in the outer dict.
- `unnecessary_spread_fix` keeps the non-empty parenthesized-wrapper logic from V1, but routes empty dict spreads through separator-aware deletion.
- `trailing_edits` now returns both the edits and the end offset of the removed closing wrapper tokens, so the empty branch can delete a single contiguous spread range.
- Added `empty_spread_edit`, `following_item_start`, and `trailing_comma_end` to implement the first/middle/last/only empty-spread obligations.

## Rejected alternatives

- Suppressing fixes for parenthesized dict spreads was rejected because `FVK-F1` and `PO2` show a direct, local way to produce a valid fix.
- Keeping V1's empty-spread behavior was rejected because `FVK-F2` gives concrete in-domain inputs where V1's edit construction leaves invalid separators.
- Broadening into comment-preservation rules for comments outside the inner dict entries was not applied. The public fixture evidence supports preserving inner-entry comments (`PO3`), while wrapper-level comments were not needed to discharge the reported syntax error or the empty-spread separator bug.

## Verification constraints

Per the benchmark instructions, all verification is by inspection and constructed proof artifacts only. The commands listed in `fvk/PROOF.md` are intentionally not executed here.
