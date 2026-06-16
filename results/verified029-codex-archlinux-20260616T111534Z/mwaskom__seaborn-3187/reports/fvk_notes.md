# FVK Notes

## Decision

V1 stands unchanged. The audit found no source defect requiring a V2 edit.

## Trace to Findings and Proof Obligations

- Kept `_add_formatter_offset` in `repo/seaborn/utils.py` unchanged because F1 and PO1 show it makes non-empty formatter offset text visible in labels, while F2 and PO2 show empty-offset labels remain unchanged.
- Kept the `locator_to_legend_entries` call site unchanged because F3 and PO3 show the helper is called after `formatter.set_locs(raw_levels)`, which is the required point where `get_offset()` has formatter loc context.
- Kept the `ContinuousBase._setup` call site unchanged because F3 and PO4 show labels are passed through the helper immediately after `format_ticks(locs)`, covering the objects API path named in the issue.
- Kept the label-based representation rather than moving the offset into legend titles because F4 and PO6 trace the choice to public intent: the issue says the offset can be used in the title and/or labels. Labels are sufficient and avoid changing title/subtitle grouping behavior.
- Made no public API refactor because F5 and PO7 show the existing patch changes no public signatures and preserves the existing `(values, labels)` and `(raw_levels, formatted_levels)` shapes.

## Residual Risk

The proof is constructed by static reasoning only. F6 records that no tests, Python execution, or K tooling were run, and the benchmark instructions forbid doing so. A future machine-checking pass could encode the helper and call-site composition claims and run the commands listed in `fvk/PROOF.md`.
