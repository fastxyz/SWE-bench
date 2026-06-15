# FVK Iteration Guidance

Status: V2 source is recommended.

## Applied Change From FVK

F-001 / PO-004 identified a V1 compatibility regression: removing the
`NdarrayMixin` import from `table.py` broke the public re-export path used by
`astropy.table.__init__`. V2 restores that import as an explicit compatibility
binding with `# noqa: F401`.

## Kept From V1

F-003 / PO-001 confirms that removing the structured-ndarray view-to-mixin branch
is the correct behavior change. V2 keeps that deletion.

## No Further Source Edits Recommended

The remaining issue, F-002, is a suspect legacy public test. The task forbids
test edits, and adapting production code to satisfy that assertion would
reintroduce the reported defect. No additional production edit is justified.

## Future Validation

In an execution-capable environment, run the recorded K commands and then the
relevant table tests. Add or update public tests for:

- `Table([structured_array], names=[...])` yields the normal column class.
- `t["name"] = structured_array` yields the normal column class.
- Explicit `NdarrayMixin` input remains a mixin.
- `from astropy.table import NdarrayMixin` continues to work.
