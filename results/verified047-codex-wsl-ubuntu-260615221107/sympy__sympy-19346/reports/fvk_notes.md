# FVK Notes

## Summary

The FVK audit confirms V1 should stand unchanged. No additional source files
were edited after the audit.

## Decisions

Decision: keep the V1 `_print_dict` method.

Trace: FVK-F2 identifies the pre-fix dict behavior as a code bug. PO1 shows the
new method is reached by built-in `dict` dispatch, PO2 shows keys and values are
recursively repr-printed, PO3 shows the output syntax remains a dict literal,
and PO6 preserves the evaluable-output contract.

Decision: keep the V1 `_print_set` method.

Trace: FVK-F1 identifies the pre-fix set behavior as a code bug. PO1, PO2, PO3,
PO4, and PO6 show that built-in sets dispatch to the new method, recursively
print elements, handle the empty-set syntax corner case, use justified
deterministic ordering, and preserve evaluability.

Decision: keep the V1 `_print_frozenset` method.

Trace: FVK-F3 shows frozenset belongs to the same built-in unordered-container
family and had the same fallback problem. PO2, PO3, PO4, and PO6 justify the
recursive rendering and concrete `frozenset(...)` output forms.

Decision: keep `default_sort_key` ordering for set elements and dict keys.

Trace: FVK-F5 resolves the order question. PO4 ties the choice to existing SymPy
printer convention rather than V1-only behavior, and the prompt does not impose
insertion-order dict display.

Decision: do not add `_print_Dict`.

Trace: FVK-F6 and PO5 show that SymPy `Dict` is separate from the built-in dict
literal examples and should not be changed without independent public intent.

Decision: make no public API changes.

Trace: PO7 is discharged: `srepr(expr, **settings)` and printer dispatch
protocols are unchanged.

## Verification Limits

No tests, Python code, `kompile`, `kast`, or `kprove` were run. FVK-F7 records
the honesty gate: the proof is constructed but not machine-checked, so no test
removal is justified in this session.
