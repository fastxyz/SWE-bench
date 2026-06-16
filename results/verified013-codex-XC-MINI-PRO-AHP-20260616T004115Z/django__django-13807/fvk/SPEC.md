# SPEC

Status: constructed, not machine-checked.

## Unit Under Audit

- `django.db.backends.sqlite3.base.DatabaseWrapper.check_constraints()`
- Scope: the SQLite branch guarded by
  `self.features.supports_pragma_foreign_key_check`.
- Public entry paths considered:
  - `django.core.management.commands.loaddata.Command.loaddata()`
  - `django.db.backends.base.creation.BaseDatabaseCreation.deserialize_db_from_string()`
  - direct `connection.check_constraints()` calls with `table_names=None`

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "loaddata crashes on SQLite when table names are SQL keywords." | Loading fixtures for a model whose SQLite table name is a SQL keyword must not fail because the table name is parsed as SQL syntax. | Encoded by O1, O2, O3. |
| I2 | prompt | "This is because the table name order is not quoted properly" and `PRAGMA foreign_key_check(order)` | The table operand of `PRAGMA foreign_key_check(<table>)` must be an identifier-quoted table name when a specific table is checked. | Encoded by O1. |
| I3 | prompt | "And here line 333" showing `PRAGMA foreign_key_list(%s)` | The table operand of `PRAGMA foreign_key_list(<table>)`, reached when reporting violations, must also be identifier-quoted. | Encoded by O2. |
| I4 | public hint | "yes, self.ops.quote_name(table_name)" | The backend-specific quoting operation is `self.ops.quote_name()`, not hand-written punctuation. | Encoded by O1 and O2. |
| I5 | implementation | `loaddata` builds `table_names = [model._meta.db_table for model in self.models]`. | `check_constraints()` receives raw model table names and must perform backend quoting itself. | Encoded by O1 and O6. |
| I6 | implementation | The modern SQLite branch raises a Django `IntegrityError` with raw names in the message after querying invalid rows. | Fixing identifier quoting must preserve the user-facing diagnostic semantics if violations exist. | Encoded by O3 and O5. |

## Intent-Only Contract

For every SQLite table name `T` in the intended domain of Django model
`db_table` names, including a reserved SQL keyword such as `order`,
`check_constraints(table_names=[T])` must:

1. Build the per-table `foreign_key_check` PRAGMA with `T` treated as an SQL
   identifier, not raw syntax.
2. If SQLite reports a violation for `T`, build the follow-up
   `foreign_key_list` PRAGMA with `T` treated as an SQL identifier.
3. If SQLite reports a violation for `T`, build the diagnostic `SELECT` with
   the table, primary-key column, and foreign-key column treated as SQL
   identifiers.
4. Preserve the previous behavior for `table_names=None`, where SQLite's
   database-wide `PRAGMA foreign_key_check` takes no table operand.
5. Preserve public API shape: no method signature, return type, exception
   type, or callsite protocol changes.

## Formalized Obligations

- O1: `quote_name(T)` must be applied before the specific-table
  `PRAGMA foreign_key_check` query is constructed.
- O2: `quote_name(T)` must be applied before the `PRAGMA foreign_key_list`
  query is constructed for violation reporting.
- O3: `quote_name()` must be applied to the table name, primary key column, and
  foreign key column before the diagnostic `SELECT` query is constructed.
- O4: `table_names=None` remains a database-wide check and constructs no table
  operand.
- O5: Returned `IntegrityError` text continues to use the raw table and column
  names for readability.
- O6: The fix is localized to the SQLite backend because callers pass raw model
  table names and identifier quoting is backend-specific.

## Abstraction Used In The K Model

The K model abstracts a SQLite identifier to two classes:

- `kw`: a SQL keyword such as `order`.
- `nonkw`: any non-keyword identifier.

It also tracks whether an identifier appears as `raw(Name)` or
`quoted(Name)`. This abstraction preserves the property under verification:
`raw(kw)` is the failing representative and `quoted(kw)` is the passing
representative. The abstraction distinguishes a passing and failing instance,
so it does not collapse the defect axis.

## Artifacts

- `fvk/mini-sqlite-check-constraints.k` defines the abstract SQL construction
  semantics.
- `fvk/sqlite-check-constraints-spec.k` states the reachability claims.
- `fvk/PROOF_OBLIGATIONS.md` lists the obligations discharged by the audit.
- `fvk/PROOF.md` gives the constructed proof and exact commands that would be
  run in an environment with K tooling.
