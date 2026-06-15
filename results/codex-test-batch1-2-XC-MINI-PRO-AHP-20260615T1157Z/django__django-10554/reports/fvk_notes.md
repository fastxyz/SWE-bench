# FVK Notes

## Decision

V1 stands unchanged. No additional production source edit is justified by the
FVK audit.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F-001 identifies the defect as aliasing of component `Query`
objects between an ordered combined queryset and a derived queryset. The V1 edit
in `repo/django/db/models/sql/query.py` directly addresses this by recursively
cloning `combined_queries` in `Query.clone()`.

`fvk/PROOF_OBLIGATIONS.md` PO-1 requires derived combined querysets to receive
cloned child queries rather than aliases of the source children. The V1 line:

```python
obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

discharges that obligation.

PO-2 and PO-3 require derived `values_list('pk')` select-list narrowing to frame
the source ordered union and leave the source order position selected. The
constructed proof in `fvk/PROOF.md` shows this with the two-child model:
derived children become width `1`, while source children stay width `4`, so the
source `ORDER BY` position remains valid.

PO-4 requires nested combined queries to be isolated as well. The recursive
call to each child query's `clone()` discharges that by applying the same rule
through the combined-query tree.

PO-5 requires compatibility. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records that
V1 changes no public signature, return shape, or `combined_queries` tuple shape.
It only changes whether tuple entries are shared or cloned.

F-002 records the only alternative considered during the FVK pass: cloning
operands inside `QuerySet._combinator_query()`. I rejected it because the public
issue is about mutation during derivation from an already-created ordered union,
and source evidence shows derivation flows through `Query.clone()`. Changing
set-operation construction would be broader than the proof obligations require.

F-003 and PO-6 record that this is a constructed proof only. I did not run
tests, Python, `kompile`, `kast`, or `kprove`, in accordance with the task
constraints. The unexecuted commands are written in `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md`.
