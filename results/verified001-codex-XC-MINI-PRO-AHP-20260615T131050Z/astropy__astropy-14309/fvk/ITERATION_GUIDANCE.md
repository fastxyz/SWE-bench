# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged.

The FVK audit found the original defect as F-001 and proved it against PO-003:
a non-FITS filepath with empty positional arguments now returns `False` without
indexing `args[0]`. The audit did not surface a justified source-code change
beyond V1.

## Future Tests to Add or Keep

Do not edit tests in this benchmark task. For maintainers, useful tests would
cover:

- `identify_format("write", Table, "bububu.ecsv", None, [], {})` does not raise
  and does not include `"fits"`.
- `is_fits("write", "bububu.ecsv", None)` returns `False`.
- FITS suffix paths still return `True`.
- FITS HDU positional objects still return `True`.
- Non-HDU positional objects still return `False`.

All test-removal ideas are conditioned on a later machine check of the emitted K
claims; no removal is recommended here.

## Future Refactoring Candidates

- A broader audit could harden sibling identifiers that have similar
  object-fallback `args[0]` patterns. This FVK pass rejects that expansion under
  F-004 and PO-006 because the public issue and stack trace localize the
  reported failure to `is_fits`.
- If Astropy wants identifier functions to be universally total for empty
  `args`, that should be specified as a registry-wide compatibility task rather
  than smuggled into this FITS-specific bug fix.

## Commands for Later Machine Checking

```sh
kompile fvk/mini-fits-identifier.k --backend haskell
kast --backend haskell fvk/fits-identifier-spec.k
kprove fvk/fits-identifier-spec.k
```
