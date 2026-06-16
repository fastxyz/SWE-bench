# Iteration Guidance

Status: no V2 source change required beyond V1.

## Decision

Keep V1 unchanged.

## Why

- F-1 confirms V1 discharges PO-1 and PO-4: the only branch where `withinLine` would read metadata from a collapsed first edge now copies `bc` into `ab`.
- F-2 confirms PO-2: the other line-degenerate branches already expose `ab` for the represented non-collapsed `A-B` segment.
- PO-3 and PO-5 confirm the patch preserves point/non-degenerate triangle classification and avoids public API or test changes.

## Future Work Outside This Issue

- Run the emitted K commands in a real K environment and require `#Top`.
- Keep or add normal regression tests for the reported flat-polygon `CONTAINS` false positive; this FVK run does not remove any tests.
- If a future task targets shape doc-values geometry queries, separately audit doc-values edge metadata. That is not part of this issue's indexed query path.
