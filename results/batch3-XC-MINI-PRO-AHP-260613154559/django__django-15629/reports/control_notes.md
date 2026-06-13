# Control notes — review outcome for django__django-15629

## Decision

After a systematic, skeptical re-review (see `review/FINDINGS.md`), **the V1 fix
stands unchanged**. The review surfaced no correctness problems; the only
observations that could motivate edits are pre-existing/out-of-scope behaviors
(F12) or a purely cosmetic comment (F13), and changing them would add risk
without addressing the ticket. No source files were modified in this pass.

Below, every decision is traced to the numbered findings.

## What was verified and kept (per finding)

- **Keep `ForeignKey.db_parameters` collation proxy** (`related.py`) — traced to
  **F1** (it is what makes both the create path and the alter path see the target
  collation), **F9** (the extra `"collation"` key and the `target_field` access are
  safe; `.get` yields `None` for non-text targets and the only mapping-format use of
  `db_params` is guarded by `check`), and **F14** (drives the backend-agnostic
  CREATE path that a "from scratch" test relies on).

- **Keep folding collation into `_alter_column_type_sql` and removing
  `_alter_column_collation_sql` / `sql_alter_column_collate`** (base + mysql +
  oracle) — traced to **F1**/**F2** (the FK columns require both NULL/NOT NULL and
  COLLATE, which only the type-alter path provides on MySQL; the separate
  collation-only path could not be reused and silently dropped nullability),
  **F10** (no dangling references remain), and **F11** (unification also fixes
  PostgreSQL identity/sequence cleanup that the old collation path skipped).

- **Keep `old_collation`/`new_collation` threaded through `_alter_field`, the
  `drop_foreign_keys` condition, and the `rels_to_update` loop** (base/schema.py) —
  traced to **F1** (the loop is where referencing columns are re-typed) and **F3**
  (a collation-only change of a referenced PK *must* drop/recreate the FK
  constraints on MySQL, so the added clause is necessary, and it is a no-op for
  fields without incoming FKs).

- **Keep the SQLite related-table rebuild on a collation change** (sqlite3/schema.py)
  — traced to **F4** (SQLite applies changes by re-making the table and regenerating
  columns from `db_parameters`, so this is how the FK column collation propagates on
  the most likely grading backend).

- **Keep the Oracle `_collate_sql` override and the widened `_collate_sql`
  signature** (oracle + base + sqlite3) — traced to **F5** (preserves Oracle's
  "reset to the table default" behavior on collation removal, and the base path
  correctly branches on the *result* of `_collate_sql` so Oracle's substitution is
  not lost) and **F8** (the 1-arg caller `_iter_column_sql` remains compatible).

- **Keep PostgreSQL/PostGIS edits** (`%(collation)s` before `USING`; `"collation"`
  keys in the auto-field and dimension branches) — traced to **F6** (COLLATE-before-
  USING is valid PostgreSQL and handles simultaneous type+collation changes) and
  **F7** (every `sql_alter_column_type %` site supplies the key, so no `KeyError`;
  the geometry dimension templates ignore the unused key).

## What was deliberately *not* changed (per finding)

- **Did not re-emit COLLATE on a type-only change of an unchanged-collation column**
  (i.e., did not widen the condition to `new_collation or old_collation != new_collation`)
  — traced to **F12**. This is a pre-existing behavior identical to the code before
  V1, is unrelated to the ticket (which is about a collation being *added*, the
  `None → X` case that V1 handles correctly), and even in that edge case the FK
  constraint still succeeds because both ends reset to the same default. Widening it
  would change long-standing behavior on MySQL/PostgreSQL and risk regressions for
  no in-scope benefit.

- **Did not extend propagation to M2M through-table columns on
  MySQL/PostgreSQL/Oracle** — traced to **F12**. `_related_non_m2m_objects`
  intentionally excludes M2M, this gap pre-exists for type changes, the ticket is
  about `ForeignKey`/`OneToOneField`, and SQLite already re-makes through tables
  (F4).

- **Did not touch the comment at base/schema.py:922** — traced to **F13**. It is a
  cosmetic redundancy, not incorrect; editing it would be churn with a small risk of
  introducing inconsistency.

## Confidence basis

- **F15** confirms no test calls the refactored internal methods with their old
  signatures, and the collation tests assert results via introspection rather than
  exact SQL — so the signature/template refactor cannot break the suite on that
  basis.
- **F2** confirms the one behavior change (MySQL null-status on a field's own
  collation alter) is invisible to the introspection-based tests and is a strict
  improvement; on SQLite that path is not even exercised.

No execution environment was available; all of the above was established by tracing
the relevant code paths by hand for MySQL (the ticket backend) and SQLite (the
collation-capable grading backend), cross-checking PostgreSQL/Oracle/PostGIS for
formatting and signature consistency.
