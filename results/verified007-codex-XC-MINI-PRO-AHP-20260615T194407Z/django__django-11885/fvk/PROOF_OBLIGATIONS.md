# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Same-Model OR Combination

Obligation: If `Collector.add_fast_delete()` is given a queryset-like fast
delete and the current list contains a queryset-like fast delete for the same
model, and the parameter guard allows it, the stored entry is replaced by
`fast_delete | qs`.

Public evidence: E-3, E-4, E-5 in `fvk/SPEC.md`.

Source evidence: `repo/django/db/models/deletion.py`, `add_fast_delete()`;
`repo/django/db/models/query.py`, `QuerySet.__or__`.

K claims: `fast-delete-spec.k` claims 1 and 2.

Status: discharged by construction.

## PO-2: Incompatible Entries Stay Separate

Obligation: If an existing fast delete is not queryset-like or does not have the
same model as the new queryset, it is not combined with the new queryset.

Public evidence: E-6; the prompt examples only combine predicates for the same
table, and Django's queryset OR primitive is same-model.

K claim: `fast-delete-spec.k` claim 3.

Status: discharged by construction.

## PO-3: Parameter-Limit Safety

Obligation: On a backend with `max_query_params`, V1 must not combine entries
when either side has unknown parameter count or their known counts exceed the
limit.

Public evidence: E-8 and the existing batching behavior that avoids oversized
queries.

K claim: `fast-delete-spec.k` claim 4.

Status: discharged by construction.

## PO-4: Semantic Preservation of Deletion Row Set

Obligation: For fast-delete predicates `P` and `Q`, deleting rows matching
`P OR Q` deletes the same final row set as deleting `P` and then `Q`. The row
count is the size of the union, matching what sequential deletes would count
after duplicates have been removed by the first delete.

Public evidence: E-4 and E-5 require OR as the combination form.

Formal treatment: This is a relational SQL/set algebra obligation, represented
in the mini semantics by the predicate constructor `P |or| Q`. It is treated as
a standard set-union property of SQL OR, not a Django-specific behavior.

Status: discharged as a domain axiom of OR predicates.

## PO-5: Reduced Round Trips

Obligation: The number of `_raw_delete()` calls for a model's compatible sibling
fast deletes is reduced from N entries to one combined entry.

Public evidence: E-3.

Source evidence: `Collector.delete()` performs one `_raw_delete()` per
`self.fast_deletes` entry.

K claim: `fast-delete-spec.k` claim 5.

Status: discharged by construction.

## PO-6: Integration With Collection Sites

Obligation: Every V1 scheduling path that previously appended directly to
`fast_deletes` must now route through `add_fast_delete()`.

Public evidence: E-2.

Source evidence: The only two direct appends in `Collector.collect()` were
replaced by `self.add_fast_delete(...)`.

K treatment: Not modeled as a separate claim; verified by static source audit of
the allowed code.

Status: discharged by source inspection.

## PO-7: Compatibility Frame

Obligation: V1 must not change the public shape of `Collector.fast_deletes` or
the behavior of non-fast deletion paths.

Public evidence: The issue asks only to combine fast delete queries.

Source evidence: `fast_deletes` remains a list of queryset-like entries;
non-fast cascade paths and `Collector.delete()` are unchanged.

Status: discharged by source inspection.
