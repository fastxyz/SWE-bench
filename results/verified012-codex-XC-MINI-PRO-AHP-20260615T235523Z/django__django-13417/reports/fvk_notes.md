# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional source edit justified
after checking the intent, compiler behavior, public compatibility, and proof
obligations.

## Trace to Findings and Proof Obligations

The original defect is recorded as `fvk/FINDINGS.md` F1. It maps to
`fvk/PROOF_OBLIGATIONS.md` PO-4: default `Meta.ordering` must not make a grouped
aggregate queryset report ordered. V1 satisfies this by adding
`not self.query.group_by` to the default-ordering branch in
`repo/django/db/models/query.py`.

The decision not to make a broader change is supported by F2 with PO-3:
explicit `order_by` and `extra_order_by` remain valid ordering sources even when
the query is grouped. Moving the group-by check ahead of explicit ordering, or
clearing ordering state during annotation, would have risked changing this
intended behavior.

The decision not to alter non-grouped default ordering is supported by PO-5.
The public property contract still says default model ordering counts, and the
compiler only suppresses that default source when grouping is active.

The decision not to alter public API shape or callsites is supported by F3 and
PO-7. `QuerySet.ordered` remains a no-argument property returning a boolean; the
audit found source callsites reading it as a property and no source override
requiring signature work.

The formal K model keeps the empty-queryset case separate from the non-empty
compiler-source cases. This modeling decision is required by PO-1 and PO-2 and
is consistent with F5: it lets the proof compare V1 against compiler-derived
orderedness for ordinary query states without weakening the existing empty
queryset behavior.

The decision not to run tests, Python, or K tooling and not to recommend test
removal is recorded in F4 and PO-8. The proof is constructed, not
machine-checked, and the benchmark explicitly forbids execution.

F5 summarizes the resulting repair decision: the proof obligations cover the
reported issue case and the adjacent preservation cases, so no V2 source edit
was made.
