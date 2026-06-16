# PUBLIC_EVIDENCE_LEDGER

| ID | Source | Public evidence | Obligation |
| --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | `QuerySet.bulk_create() crashes on mixed case columns in unique_fields/update_fields.` | Support db columns whose spelling differs from model field names. |
| I2 | `benchmark/PROBLEM.md` | `ON CONFLICT("blacklistid")` fails with `column "blacklistid" does not exist`. | Do not use model field names as conflict SQL identifiers. |
| I3 | `benchmark/PROBLEM.md` | Expected `ON CONFLICT("BlacklistID") DO UPDATE SET "SectorID" = EXCLUDED."SectorID"`. | Use database column names for both unique and update fields. |
| I4 | `repo/docs/ref/models/fields.txt` | `Field.db_column`: database column name, falling back to field name. | `Field.column`/`db_column` semantics are the source of database identifiers. |
| I5 | `repo/django/db/models/fields/__init__.py` | `get_attname_column()` returns `self.db_column or attname`. | Resolving to `Field` gives access to correct database column values. |
| I6 | `repo/docs/ref/models/querysets.txt` | `update_conflicts=True` updates `update_fields`; PostgreSQL and SQLite require `unique_fields`. | Apply the new conversion to the update-conflict path. |
| I7 | backend source | PostgreSQL, SQLite, and MySQL/MariaDB map `quote_name` over the supplied field identifiers. | Compiler must supply backend hooks identifier strings that are already database column names. |
