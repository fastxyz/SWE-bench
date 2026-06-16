# INTENT_SPEC

Status: intent-only summary from public evidence.

1. `bulk_create(update_conflicts=True, update_fields=..., unique_fields=...)`
   must generate valid conflict-update SQL when model fields define
   `db_column`.
2. Conflict target identifiers for `unique_fields` must be database column names.
3. Update assignment identifiers for `update_fields` must be database column
   names.
4. `Field.db_column` defines the database column name; if absent, the field name
   is used.
5. The fix should not change unrelated non-upsert `bulk_create()` behavior.
6. Backend `on_conflict_suffix_sql()` hooks should continue receiving database
   identifier strings to quote.
