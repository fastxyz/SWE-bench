# Baseline notes — django__django-11885: Combine fast delete queries

## Issue

When `deletion.Collector` emulates `ON DELETE CASCADE`, related objects that
qualify for the "fast delete" path are removed with bare
`DELETE FROM table WHERE fk IN (...)` queries that never load rows into memory.
However, when several foreign keys on the *same* table point at the object being
deleted, each FK produced its own separate `DELETE` query. The issue asks that
such per-table queries be combined into a single statement using `OR`, e.g.

```
DELETE FROM entry WHERE created_by_id IN (...)
DELETE FROM entry WHERE updated_by_id IN (...)
```

should become

```
DELETE FROM entry WHERE created_by_id IN (...) OR updated_by_id IN (...)
```

This halves (or, generally, divides by N) the number of round trips to the
database for those tables.

## Root cause

In `Collector.collect()` the fast-delete querysets were built and appended one at
a time, *inside* the per-relation / per-batch loop:

```python
for related in get_candidate_relations_to_delete(model._meta):
    ...
    batches = self.get_del_batches(new_objs, field)
    for batch in batches:
        sub_objs = self.related_objects(related, batch)
        if self.can_fast_delete(sub_objs, from_field=field):
            self.fast_deletes.append(sub_objs)   # one queryset per FK
```

Each reverse relation pointing at the model produced an independent queryset
(`related_objects` filtered on a single field), so a table with multiple FKs to
the deleted model yielded multiple `fast_deletes` entries and therefore multiple
`DELETE` statements in `delete()`.

Nothing ever grouped these by their target table, even though all fast-deletable
models are guaranteed to have no inbound cascades or signals
(`can_fast_delete`), which means the rows can be deleted in any order and freely
combined.

## Fix

The fast deletes are now grouped by their related **model** and emitted as a
single combined queryset per batch whose `WHERE` clause ORs every contributing
foreign key together. All changes are in `django/db/models/deletion.py`, plus the
matching `NestedObjects` override in `django/contrib/admin/utils.py`.

### `django/db/models/deletion.py`

1. **Imports** — added `defaultdict`, `functools.reduce`, `operator.or_`, and
   `query_utils` (for `Q`). `query_utils` is the dedicated low-level module that
   exists precisely to be importable without circular-import problems, so this is
   safe even though `deletion` is imported early by `django.db.models.__init__`.

2. **`can_fast_delete()`** — changed `model = type(objs)` to
   `model = objs._meta.model`. `Options.model` resolves to the model class for
   *both* a model instance and a model *class* (`Instance._meta.model` and
   `Model._meta.model` are identical), so this is behaviorally identical for the
   existing call sites while additionally allowing a model class to be passed in.
   This lets fast-deletability (which depends only on the model + `from_field`,
   never on the actual rows) be decided once per relation, before any queryset is
   built.

3. **`get_del_batches(objs, fields)`** — the second argument is now a *list of
   fields* instead of a single field. The batch size is computed from
   `bulk_batch_size(field_names, objs)`. This is the key to keeping the
   combination safe: backends that cap query parameters (SQLite, Oracle) return
   `max_query_params // len(fields)`, so an OR of N `IN (...)` clauses still
   stays within the parameter limit. The previous code already wrapped the single
   field as `[field.name]`, so single-field callers are unchanged.

4. **`related_objects(related_model, related_fields, objs)`** — new signature.
   It builds `reduce(or_, Q(field__in=objs) for field in related_fields)` and
   filters the related model's base manager with that predicate, producing one
   queryset that covers every supplied field with an `OR`. With a single field
   this is exactly equivalent to the old `filter(**{fk__in: objs})`.

5. **`collect()`** — the `collect_related` block now:
   - decides fast-deletability once per reverse relation via
     `can_fast_delete(related_model, from_field=field)` and, when fast-deletable,
     records the field under `model_fast_deletes[related_model]` and `continue`s;
   - runs the existing non-fast path (deferring/`only()`, on_delete handler) using
     the new `related_objects(related_model, [field], batch)` /
     `get_del_batches(new_objs, [field])` signatures;
   - after the relation loop, iterates `model_fast_deletes`, batching `new_objs`
     against *all* of that model's collected fields and appending one combined
     queryset per batch to `self.fast_deletes`.

   The `delete()` fast-delete loop itself is untouched — it simply now iterates
   over fewer, combined querysets.

### `django/contrib/admin/utils.py`

`NestedObjects.related_objects` overrode the base method, so its signature was
updated to `(self, related_model, related_fields, objs)` and it now calls
`qs.select_related(*[f.name for f in related_fields])`. `NestedObjects` always
returns `False` from `can_fast_delete`, so `related_fields` is always a single
element there and the behavior is identical to the previous
`select_related(related.field.name)`.

## Why this is correct / counts stay consistent

- **Ordering**: fast-deletable models have all inbound FKs set to `DO_NOTHING`
  and no signal listeners (`can_fast_delete`), so they participate in no cascade
  and have no inter-dependencies. They were already all executed before the main
  instance deletes inside the same atomic block, so combining/reordering them is
  safe.
- **Deleted-row counts**: with separate queries, a row matching two FKs is
  deleted by the first query and not re-counted by the second
  (`rowcount` sums to the size of the union). The combined `OR` query deletes the
  same union in one shot and reports that union's `rowcount`. The total reported
  by `delete()` is unchanged.
- **No subqueries introduced**: filtering a FK with `__in` against instances
  compares the local `*_id` column directly (no join), so the combined queryset
  uses only the base table. `DeleteQuery.delete_qs` therefore copies the `WHERE`
  clause directly (`DELETE FROM ... WHERE a IN (...) OR b IN (...)`) rather than
  falling back to a subquery.

## Assumptions / alternatives considered and rejected

- **Combine in `delete()` via the `|` operator instead of at collection time.**
  Rejected: grouping finished querysets and OR-ing them post-hoc would merge
  across the *batches* produced by `get_del_batches`, recreating arbitrarily large
  `IN (...)` lists and breaking the parameter-limit protection that batching
  exists to provide. Grouping fields *before* batching lets `bulk_batch_size`
  account for the field count, which is the correct place to combine.
- **Leave `can_fast_delete` taking only querysets.** Rejected as clumsier: it
  would force building and discarding a throwaway queryset per relation merely to
  detect fast-deletability, whereas the decision is purely model-level. The
  `objs._meta.model` tweak makes passing a class clean and is equivalent for all
  existing instance/queryset callers.
- **Add a release note / docs change.** Skipped to keep the change minimal and
  targeted to the behavior fix; `related_objects`/`get_del_batches` are internal
  collector helpers (the only external override, admin's `NestedObjects`, is
  updated in lockstep).
