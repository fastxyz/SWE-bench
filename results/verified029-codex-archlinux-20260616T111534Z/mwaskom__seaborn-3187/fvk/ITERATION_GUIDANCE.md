# FVK Iteration Guidance: mwaskom__seaborn-3187

Status: V1 stands unchanged.

## Decision

Keep V1 source code as-is. The FVK audit found that the candidate patch discharges the public intent obligations without requiring additional production edits.

## Why No Code Edit Is Needed

- F1 and PO1 show that non-empty formatter offsets are now included in labels.
- F2 and PO2 show that ordinary empty-offset labels remain unchanged.
- F3, PO3, and PO4 show that both named public paths are covered.
- F5 and PO7 show that public compatibility is preserved.
- F4 and PO6 show that choosing labels instead of titles is permitted by public intent.

## Suggested Future Tests

Do not edit tests in this benchmark task. For a normal development pass, add focused tests for:

- `locator_to_legend_entries` with numeric levels large enough for `ScalarFormatter.get_offset()` to be non-empty.
- Objects API continuous semantic legend labels under the same offset condition.
- Regression coverage that labels are unchanged when `get_offset()` returns an empty string.

## Machine-Check Follow-Up

No K commands were run. A future full FVK pass could encode the string/list helper and call-site composition claims in standalone K files and then run:

```sh
kompile fvk/mini-legend-format.k --backend haskell
kast --backend haskell fvk/legend-format-spec.k
kprove fvk/legend-format-spec.k
```

Until that exists and returns `#Top`, the proof remains constructed, not machine-checked.
