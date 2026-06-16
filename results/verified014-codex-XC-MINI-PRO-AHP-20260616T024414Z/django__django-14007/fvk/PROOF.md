# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Claims Proved in the Constructed Model

The proof covers the abstracted post-fetch part of
`SQLInsertCompiler.execute_sql()` and its positional consumers.

1. If `returning_fields` is falsey, execution returns `[]`.
2. If the backend returns multiple insert rows, execution returns
   `ConvertRows(raw_rows, returning_fields)`.
3. If the backend returns a single insert row through
   `fetch_returned_insert_columns()`, execution returns
   `ConvertRows([raw_row], returning_fields)`.
4. If the backend exposes only `last_insert_id()`, execution returns
   `ConvertRows([(raw_pk,)], [pk])`.
5. `Model._save_table()` and `QuerySet.bulk_create()` assign values that are
   already converted because their only source is `_insert()` /
   `execute_sql()`.

## Symbolic Execution Sketch

Start in a state with symbolic:

- `RF`, the requested `returning_fields`;
- feature booleans `bulkRows` and `insertColumns`;
- raw backend row data `Rows`;
- primary key field `PK`;
- query table `T`.

Case split on `RF`.

### Case 1: no `returning_fields`

The branch `if not self.returning_fields: return []` fires. The result is
exactly `[]`. This discharges PO-007.

### Case 2: bulk insert rows

Assume `bulkRows` and `len(objs) > 1`. The branch assigns:

```text
rows = fetch_returned_insert_rows(cursor)
fields = returning_fields
```

After leaving the cursor block, the common conversion suffix computes:

```text
converters = get_converters([field.get_col(T) for field in fields])
```

By the definition of `get_converters()`, each position receives backend
converters followed by field converters. If converters exist, `apply_converters`
maps over every row and every converter position. `map(tuple, rows)` restores
tuple rows, and `list(rows)` materializes the result. This discharges PO-001,
PO-002, PO-004, and PO-006 for the bulk branch.

### Case 3: single insert returning columns

Assume `insertColumns`. The branch assigns:

```text
rows = [fetch_returned_insert_columns(cursor, returning_params)]
fields = returning_fields
```

The same conversion suffix from Case 2 applies to the single row. This
discharges PO-001, PO-002, PO-003, and PO-006 for `create()` and single-row
insert callers.

### Case 4: last insert id fallback

Assume neither insert-returning branch applies. The branch assigns:

```text
rows = [(last_insert_id(cursor, table, pk_column),)]
fields = [pk]
```

The common conversion suffix applies converters for the primary-key field only.
This matches the sole value the fallback actually fetched, discharging PO-005
and preserving the prior one-column shape.

## Consumer Proof

`Model._save_table()` obtains `results` only through `_do_insert()` and assigns:

```text
for value, field in zip(results[0], returning_fields):
    setattr(self, field.attname, value)
```

For returning backends, each `value` in `results[0]` has already been converted
by Cases 2 or 3. Therefore the model attribute receives the converted value.

`QuerySet.bulk_create()` obtains `returned_columns` only through
`_batched_insert()` -> `_insert()` -> `execute_sql()`. For supported returning
backends, each `results` row has already been converted by Case 2 or 3 before
the positional assignment loop. Therefore `bulk_create()` receives converted
primary keys and other returned fields.

## Adequacy Check

The formal claims match the intent-only obligations in `SPEC.md`:

- They require converter application on insert-returned rows.
- They use the existing Django converter order.
- They cover both `create()` and supported `bulk_create()` assignment paths.
- They preserve the no-returning and last-insert-id frame behavior.

No claim depends on the issue's raw integer legacy output as expected behavior.

## Exact Commands Not Run

These are the commands that would be used to machine-check the K sketches later:

```sh
kompile fvk/mini-django-insert.k --backend haskell
kast --backend haskell fvk/django-insert-returning-spec.k
kprove fvk/django-insert-returning-spec.k
```

Expected result after completing the sketch into a runnable K definition:
`#Top`.

## Test Recommendation

Do not remove tests. Because the proof is constructed but not machine-checked,
any test-redundancy claim is conditional. Useful tests to add or keep are:

- `create()` with a custom `BigAutoField.from_db_value()` wrapper.
- `bulk_create()` with the same custom field on a backend that returns rows.
- A backend-converter-sensitive returning field to ensure backend converters
  still precede field converters.
- A fallback `last_insert_id()` path where the primary-key field has a converter.

