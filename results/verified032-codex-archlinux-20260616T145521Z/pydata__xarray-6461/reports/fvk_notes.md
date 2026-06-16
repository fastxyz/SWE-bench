# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no production-code defect beyond the issue V1 already addressed. The decision is based on findings F1-F4 and proof obligations PO1-PO5.

## Trace to Findings and Obligations

No additional scalar guard was added because F1 and PO1 show the V1 callable no longer indexes `attrs[1]`; scalar `x` produces an empty `x_attrs` list and reaches `return {}`.

No fallback to `attrs[1] if present` was introduced because F2 and PO2/PO4 show that such a patch can still preserve attrs from `y` when `x` is scalar. V1's source-based selector is stricter and matches the public `keep attrs of x` contract.

No simplification to `getattr(x, "attrs", {})` was made because F3 and PO3 cover Dataset/Variable/coordinate merge contexts where the relevant attrs source may be a variable or coordinate attrs dictionary associated with `x`, not only `x.attrs`.

No public API or method-dispatch edits were made because F4 and PO5 show V1 changes only the internal callable generated for `keep_attrs is True`; the `where` signature and `apply_ufunc` call shape remain unchanged.

No tests were run, generated, removed, or modified because PO6 and F5 record the task's no-execution and no-test-edit constraints. The proof artifacts include the commands needed for a later machine check.
