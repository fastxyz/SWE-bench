# Findings

Status: constructed, not machine-checked. Findings are based on public issue text and source reasoning only.

## F-001: V1 bug shape is a real code bug and is fixed

Input:

```text
table = "app_model"
columns = ["deleted_col"]
name = "explicit_unique_name"
query = Statement.references_column("app_model", "deleted_col")
```

Observed before the baseline fix:

```text
False
```

Reason: `_create_unique_sql()` passed `Table("app_model", quote_name)` into `_index_columns()`, so the resulting `Columns.table` value was a `Table` object. `TableColumns.references_column()` compares that object to the raw string `"app_model"`, which fails. With an explicit unique name, the name part is a quoted string and cannot compensate for the bad columns part.

Expected:

```text
True
```

Trace: E-001 through E-004, PO-001, C-001.

Resolution: fixed in V2 by keeping `table = model._meta.db_table` as a raw string for `IndexName`, `_index_columns()`, and `Expressions`.

## F-002: V1 one-line fix was behaviorally correct but left the root cause easy to reintroduce

Input:

```text
_create_unique_sql()` local variable `table`
```

Observed in V1:

```text
table = Table(model._meta.db_table, self.quote_name)
columns = self._index_columns(model._meta.db_table, ...)
```

Expected:

```text
table = model._meta.db_table
columns = self._index_columns(table, ...)
Statement(..., table=Table(table, self.quote_name), ...)
```

Reason: the V1 behavior met PO-001, but its local variable still used `table` for the renderable wrapper while sibling `_create_index_sql()` uses `table` for the raw table name. The FVK compatibility audit identifies the raw-name-first protocol as the invariant to preserve.

Trace: E-005, E-006, PO-003, PO-004.

Resolution: V2 applies the targeted refactor.

## F-003: No shared-helper change is justified

Input:

```text
TableColumns.references_column(table, column)
```

Observed:

```text
self.table == table and column in self.columns
```

Expected:

```text
The comparison remains direct raw-name equality.
```

Reason: changing `TableColumns` to unwrap or accept `Table` objects would broaden the accepted state space and weaken the producer contract. The public issue points to the producer passing the wrong type, not to a consumer that should accept mixed types.

Trace: E-002, E-003, PO-004, PO-005.

Resolution: `ddl_references.py` remains unchanged.

## F-004: Proof honesty limitation

The FVK proof is constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or Django tests were run. The emitted commands in `fvk/PROOF.md` document how to machine-check the K artifacts later.

