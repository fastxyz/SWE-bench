# PUBLIC EVIDENCE LEDGER

Status: constructed, not machine-checked.

| ID | Source | Quote or code excerpt | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "loaddata crashes on SQLite when table names are SQL keywords." | Reserved-word table names are in scope for the fix. |
| E2 | `benchmark/PROBLEM.md` | `PRAGMA foreign_key_check(order)` and "near \"order\": syntax error" | Raw keyword identifiers in the PRAGMA are the observed bug. |
| E3 | `benchmark/PROBLEM.md` | "And here line 333" showing `PRAGMA foreign_key_list(%s)` | The follow-up PRAGMA is part of the intended fix surface. |
| E4 | `benchmark/PROBLEM.md` hints | "yes, self.ops.quote_name(table_name)" | Use backend quoting rather than hard-coded quoting syntax. |
| E5 | `repo/django/core/management/commands/loaddata.py` | `table_names = [model._meta.db_table for model in self.models]` | Callers pass raw table names to the backend. |
| E6 | `repo/django/db/backends/base/creation.py` | `table_names.add(obj.object.__class__._meta.db_table)` | Database deserialization is another raw-table-name caller. |
| E7 | `repo/django/db/backends/sqlite3/introspection.py` | `PRAGMA table_info(%s)` with `self.connection.ops.quote_name(table_name)` | Existing SQLite backend convention is to quote PRAGMA table operands. |
