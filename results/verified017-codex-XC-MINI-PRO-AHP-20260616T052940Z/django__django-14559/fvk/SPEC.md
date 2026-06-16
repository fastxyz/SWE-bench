# FVK Specification: django__django-14559

Status: constructed, not machine-checked. No tests, Python, K tooling, or
external sources were run.

## Scope

Audited unit: `QuerySet.bulk_update(self, objs, fields, batch_size=None)` in
`repo/django/db/models/query.py`.

The audit focuses on the public API result of a successful `bulk_update()` call.
Database expression construction, SQL compilation, transaction rollback, and the
meaning of `QuerySet.update()` row counts are treated as existing Django
subsystems. The formal unit proof models `update()` as a call that returns the
integer number of rows matched, matching the issue's public intent.

## Public Intent Ledger

I-1. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Include number of rows matched in bulk_update() return value"
and "Currently, bulk_update() returns None, unlike update(), which returns the
number of rows matched."

Semantic obligation: on a successful call, `bulk_update()` must return an
integer row-match count rather than `None`.

Status: encoded by PO-1 and PO-4.

I-2. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "bulk_update() simply calls update() repeatedly" and "the
return values could simply be added and returned."

Semantic obligation: if `bulk_update()` performs batched `update()` calls with
return values `r_0 ... r_n`, its return value is `sum(r_i)`.

Status: encoded by PO-4.

I-3. Source: `benchmark/PROBLEM.md` public hints.

Quoted evidence: "bulk_update returning int" and "Let's just make it return the
updated rows".

Semantic obligation: return a plain integer, not a named tuple or future-proof
wrapper.

Status: encoded by PO-1 and FINDING F-5.

I-4. Source: `benchmark/PROBLEM.md` public hints.

Quoted evidence: "Duplicates split between batches will be counted twice" and
"I did not handle duplicates, and did not future-proof bulk_update."

Semantic obligation: duplicate primary keys across batches are not a separate
deduplication requirement for this issue. The count follows the sum of actual
batched `update()` return values.

Status: encoded by PO-4 and FINDING F-4.

I-5. Source: current source code.

Quoted evidence: `QuerySet.update()` stores `rows = ...execute_sql(CURSOR)` and
`return rows`.

Semantic obligation: the implementation can obtain the desired integer by using
the return values from the existing batched `update()` calls.

Status: implementation evidence for PO-4, not independent intent.

I-6. Source: existing `bulk_update()` validation code and public API shape.

Quoted evidence: existing guards reject invalid `batch_size`, empty `fields`,
objects without primary keys, non-concrete fields, many-to-many fields, and
primary key fields.

Semantic obligation: the fix should preserve existing validation and only change
the successful return value.

Status: encoded by PO-5.

## Intent Spec

For normal-return executions where the existing validation accepts the inputs
and the database update calls return normally:

1. If `objs` is empty after conversion to a tuple, `bulk_update()` returns `0`.
   This is the empty sum and the number of matched rows for no update calls.
2. If `objs` is non-empty, the existing batch construction and `CASE` update
   argument construction are preserved.
3. Let `updates = [(pks_0, kwargs_0), ..., (pks_n, kwargs_n)]` be the list built
   by the existing batching code.
4. Let `r_i` be the integer returned by
   `self.filter(pk__in=pks_i).update(**kwargs_i)`.
5. `bulk_update()` returns `r_0 + ... + r_n`.
6. The method signature remains unchanged. The return shape changes from `None`
   to `int`, which is the requested public API change.

Out-of-domain or exceptional executions are not newly specified by this issue.
Existing validation exceptions and transaction failure behavior are frame
conditions, not the target of the proof.

## Reduced Formal Model

The mini-model abstracts away ORM expression details and database internals:

- `make_updates(objs, fields, batch_size)` represents the existing deterministic
  construction of `(pks, update_kwargs)` batches.
- `rowcount(pks, update_kwargs)` represents the integer returned by
  `QuerySet.update()` for that batch.
- `sum_rowcounts(updates)` is defined recursively:
  - `sum_rowcounts([]) = 0`
  - `sum_rowcounts([u] + rest) = rowcount(u) + sum_rowcounts(rest)`

Formal claim BU-EMPTY:

```text
ValidBulkUpdateInput(objs=[], fields, batch_size)
  => bulk_update(objs, fields, batch_size) returns 0
```

Formal claim BU-SUM:

```text
ValidBulkUpdateInput(objs, fields, batch_size) and objs != []
  => bulk_update(objs, fields, batch_size)
     returns sum_rowcounts(make_updates(objs, fields, batch_size))
```

Loop/circularity claim BU-LOOP:

```text
After consuming the first k elements of updates,
rows_matched = sum(rowcount(updates[i]) for i in 0 <= i < k).

One more loop body step changes rows_matched to
rows_matched + rowcount(updates[k]), preserving the invariant for k + 1.

At k = len(updates), rows_matched equals the sum over all updates and is
returned.
```

## Adequacy Check

The formal claims say exactly that successful `bulk_update()` returns the empty
sum for empty input or the sum of the integer row counts from the actual batched
`update()` calls. This matches I-1 and I-2. The claims deliberately do not add a
named tuple return type, duplicate deduplication, or changed validation behavior,
matching I-3, I-4, and I-6.

## Public Compatibility Audit

The changed public symbol is `QuerySet.bulk_update()`. Its signature is
unchanged. Its successful return value intentionally changes from `None` to
`int`.

In-repo non-test source callsites found under `repo/django/` either refer to a
different migration-state context manager named `bulk_update()` or ignore the
`QuerySet.bulk_update()` return value. Those callsites remain compatible with an
integer return.

Manager access to `bulk_update()` uses Django's existing QuerySet-to-Manager
delegation and needs no paired source change.
