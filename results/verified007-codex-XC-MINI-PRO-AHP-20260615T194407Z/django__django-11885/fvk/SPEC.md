# FVK Spec: django__django-11885

Status: constructed, not machine-checked.

## Intent Spec

The public issue requires Django's deletion collector to combine fast-delete
queries generated while emulating `ON DELETE CASCADE` when those queries target
the same related table. The required observable is fewer database round trips:
instead of executing one DELETE for each sibling cascade predicate, the collector
should execute one DELETE whose WHERE predicate is the OR of those sibling
predicates.

Required behaviors:

- I-1: For a self many-to-many through table, `from_id = :id` and `to_id = :id`
  fast-delete predicates for the through table combine into one OR predicate.
- I-2: For a related model with multiple foreign keys to the deleted model,
  sibling fast-delete predicates such as `created_by_id = :id` and
  `updated_by_id = :id` combine into one OR predicate.
- I-3: Combining must preserve deletion semantics: deleting by `P OR Q` must
  delete the same row set as deleting by `P` and then by `Q`, modulo duplicate
  matches that a second DELETE would no longer count.
- I-4: Existing safety constraints on fast deletion remain in force. The issue
  asks to combine fast deletes only after the collector has determined that the
  fast path is valid.
- I-5: Backend query-parameter limits must not be violated by the optimization.
  This is a default database-backend safety obligation inferred from the existing
  batching logic in `Collector.get_del_batches()`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | prompt | "Combine fast delete queries" | Add an optimization in deletion collection, not a model-level behavior change. | Encoded by PO-1, PO-5. |
| E-2 | prompt | "the deletion.Collector will try to perform fast queries" | Scope is `Collector` fast-delete scheduling. | Encoded by PO-1. |
| E-3 | prompt | "combine such queries by table to reduce the number of roundtrips" | Compatible entries for the same table should become fewer `fast_deletes` entries. | Encoded by PO-1, PO-5. |
| E-4 | prompt | `DELETE FROM person_friends WHERE from_id = :id OR to_id = :id` | OR predicate is the required shape for self-M2M through-table deletes. | Encoded by PO-1, claim 2. |
| E-5 | prompt | `DELETE FROM entry WHERE created_by_id = :id OR updated_by = :id` | OR predicate is the required shape for multiple FK relations to the same related model. | Encoded by PO-1, claim 1. |
| E-6 | code | `QuerySet.__or__` calls `query.combine(..., sql.OR)` | Existing public queryset operation provides the intended OR-combination primitive. | Used as implementation evidence. |
| E-7 | code | `Collector.delete()` loops `for qs in self.fast_deletes` and calls `_raw_delete()` | Number of final `fast_deletes` entries is the round-trip count for fast deletes. | Encoded by PO-5. |
| E-8 | code | `get_del_batches()` uses backend bulk batch size | Parameter safety is part of existing deletion behavior and must be preserved. | Encoded by PO-3. |

## Formal Model

The formal core is in:

- `fvk/mini-fast-delete.k`
- `fvk/fast-delete-spec.k`

The model abstracts a fast-delete queryset as `fd(model, predicate, count)`.
`model` is the table-owning Django model for the fast-delete queryset,
`predicate` is the WHERE predicate, and `count` is either the known number of
query parameters contributed by the relation batch or `unknown`.

The abstraction is property-complete for this issue because it preserves the
observable axes the issue names:

- table/model compatibility;
- OR predicate shape;
- number of fast-delete entries, which maps to `_raw_delete()` round trips;
- parameter-limit safety.

It deliberately abstracts away SQL rendering, database rows, signals, and model
instance collection because the public issue concerns only the fast-delete query
combination step after the fast path is already valid.

## Formal Spec English

- Claim 1: If an existing fast delete for `Entry.created_by` and a new fast
  delete for `Entry.updated_by` have known parameter counts whose sum is within
  the backend limit, `addFast` returns a single `Entry` fast delete with
  `created_by OR updated_by` and the summed parameter count.
- Claim 2: If an existing fast delete for `PersonFriends.from_id` and a new fast
  delete for `PersonFriends.to_id` are within the backend limit, `addFast`
  returns a single `PersonFriends` fast delete with `from_id OR to_id`.
- Claim 3: If the new fast delete is for a different model/table, `addFast`
  preserves the existing entry and appends the new one.
- Claim 4: If same-model known parameter counts would exceed the backend limit,
  `addFast` preserves the existing entry and appends the new one.
- Claim 5: In the reported two-FK case with enough parameter budget, the final
  fast-delete list has one entry, so `Collector.delete()` performs one raw delete
  for the related model instead of two.

## Spec Audit

All five formal-English claims are entailed by the intent ledger.

Claims 1, 2, and 5 directly encode E-3, E-4, and E-5. Claim 3 is a frame
condition from the existing `QuerySet.__or__` compatibility boundary: combining
different models is not requested by the examples and is not supported by the
local OR primitive. Claim 4 is a safety frame condition from E-8.

The phrase "by table" is interpreted as same fast-delete model/table for the
querysets produced by `Collector.related_objects()`. The public examples use
normal Django model-owned tables, and the in-repo OR primitive combines same
model querysets. No public evidence requires a lower-level SQL combiner for two
distinct model classes sharing one physical table.

## Public Compatibility Audit

Changed public symbols:

- `Collector.add_fast_delete()` is new and internal to `Collector`.

Changed call shapes:

- Direct internal appends in `Collector.collect()` now call
  `self.add_fast_delete(...)`.
- No in-repo callsites outside `django/db/models/deletion.py` reference
  `fast_deletes` directly.
- `Collector.fast_deletes` remains a list of queryset-like objects, preserving
  its observable shape for code that inspects it.

No public override or subclass compatibility issue was found in the allowed
source tree.

## Machine-Check Commands

These commands are recorded for a later environment with K installed. They were
not executed in this session.

```sh
kompile fvk/mini-fast-delete.k --backend haskell
kast --backend haskell fvk/fast-delete-spec.k
kprove fvk/fast-delete-spec.k
```
