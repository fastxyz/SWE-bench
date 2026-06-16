# Iteration Guidance

Status: V2 source is recommended.

## Code decision

Keep the behavioral fix from V1 and keep the V2 refactor:

```text
table = model._meta.db_table
...
columns = self._index_columns(table, ...)
...
table=Table(table, self.quote_name)
```

This implements PO-001 and PO-004 while preserving PO-005.

## Do not change

Do not change `TableColumns.references_column()` to accept `Table` objects. F-003 explains why the producer was wrong and the consumer contract is coherent.

Do not modify tests in this benchmark task.

## Future verification work

The next useful checks, if a runnable environment exists later, are:

- Run the emitted K commands from `fvk/PROOF.md`.
- Add or run a Django schema-editor test for an explicit-name unique statement in `deferred_sql` when a referenced column is removed.
- Add or run a backend-specific check for PostgreSQL `IndexColumns` with opclasses.

## Stop condition

No unresolved FVK finding requires further source edits. The remaining limitation is proof machine-checking, not a source-code gap.

