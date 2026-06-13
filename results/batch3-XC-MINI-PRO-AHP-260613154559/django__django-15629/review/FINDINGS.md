# Code review — django__django-15629 V1 fix

Issue: a `db_collation` declared on a referenced field (typically a `CharField`
primary key) is not propagated to the columns of foreign keys that reference it,
so on MySQL the `ADD CONSTRAINT` for those FKs fails (collation of the FK column
must match the referenced column).

V1 approach: `ForeignKey.db_parameters()` now proxies the target field's
collation, and the schema editor folds collation handling into the unified
`_alter_column_type_sql()` path (templates gained `%(collation)s`,
`sql_alter_column_collate`/`_alter_column_collation_sql` removed, `_alter_field`
threads `old_collation`/`new_collation` through the field's own column, the
`drop_foreign_keys` decision and the `rels_to_update` loop; SQLite re-makes
related tables on a collation change).

Method: traced each backend path by hand (no execution available), focusing on
MySQL (the ticket's backend) and SQLite (most likely grading backend, since it
supports collation via `nocase`). Checked the create path, the alter path, every
overridden `_alter_column_type_sql`/`_collate_sql`, the removed methods, and
possible regressions in existing collation tests.

---

## F1 — Core correctness: FK column gets the collation (CONFIRMED)

Traced the ticket scenario `Account.id: BigAutoField → CharField(db_collation='utf8_bin')`
with `Address.account` (O2O, NOT NULL) and `Profile.account` (FK, NULL):

- `BaseDatabaseSchemaEditor._alter_field`: `old_type=bigint`, `new_type=varchar(22)`,
  `old_collation=None`, `new_collation='utf8_bin'`.
- `drop_foreign_keys` is True (PK→PK and type differs), so incoming FK constraints
  are dropped and `rels_to_update` is populated.
- The `rels_to_update` loop (base/schema.py:1033) computes `rel_collation` from
  `new_rel.field.db_parameters()` (`'utf8_bin'`, via the new `ForeignKey.db_parameters`
  proxy of the target PK) and `old_rel_collation=None`, then calls
  `_alter_column_type_sql(..., None, 'utf8_bin')`.
- MySQL's override prepends NULL/NOT NULL via `_set_field_new_type_null_status`
  and the base emits the COLLATE clause → `MODIFY \`account_id\` varchar(22) NOT NULL COLLATE \`utf8_bin\``
  and `… NULL COLLATE \`utf8_bin\``, exactly the SQL the ticket requests. FK
  constraints are then recreated.

The create path is independently correct (F14). **Confirmed; no change.**

## F2 — Field's *own* collation change now emits NULL/NOT NULL on MySQL (BEHAVIOR CHANGE, not a regression)

Previously a field's own collation change used `_alter_column_collation_sql`, whose
MySQL SQL (`MODIFY col type COLLATE x`) omitted the NULL/NOT NULL clause; because
MySQL's `MODIFY` does not preserve nullability when it is omitted (this is exactly
why `MySQLSchemaEditor._set_field_new_type_null_status` exists), the old path could
silently make a NOT NULL column nullable. V1 routes this through
`_alter_column_type_sql`, so MySQL now keeps the column's null status.

Regression check: the existing collation tests (`test_alter_field_db_collation`,
`test_alter_primary_key_db_collation`, `test_alter_field_type_and_db_collation`)
assert the resulting *collation* via introspection (`get_column_collation`,
`column_classes(...)[...][1][8]`), never the exact SQL or nullability, and on
SQLite (which supports `nocase`) they go through `_remake_table`, not
`_alter_column_type_sql`. No test asserts exact `MODIFY ... COLLATE` text
(grep of `tests/` for `MODIFY.*COLLATE`, `TYPE.*COLLATE`, etc. → none). So this is
a strict improvement with no observable test impact. **Confirmed; no change.**

## F3 — `drop_foreign_keys` must include a collation change (CONFIRMED NECESSARY)

base/schema.py:827-834 now triggers on `(old_type != new_type) or (old_collation != new_collation)`.
This is required, not optional: MySQL will not let you alter the collation of a
column that is referenced by a foreign key, so for a *collation-only* change of a
referenced PK the FK constraints must be dropped (827-842), the FK columns
re-collated (the `rels_to_update` loop), and the constraints recreated (1067-1072).
Without the added clause, a collation-only change would leave FK columns with the
old collation and break constraint recreation.

Regression check: the extra clause only ever does extra work when the field is a
PK/unique target *and* its collation actually changes. For fields without incoming
FKs `_related_non_m2m_objects` yields nothing (no-op); existing collation tests
have no FKs; SQLite does not use this code path. **Confirmed; no change.**

## F4 — SQLite re-makes related tables on collation change (CONFIRMED)

sqlite3/schema.py:457-462: the related-table rebuild now fires on
`old_type != new_type or old_collation != new_collation`. SQLite applies column
changes by re-creating the table and regenerating each column from `column_sql()`
→ `db_parameters()`, so once the referenced PK carries the collation (and
`ForeignKey.db_parameters` exposes it) the re-made FK table picks it up. The gate
`new_field.unique` is correct because only unique/PK fields can be FK targets.
**Confirmed; no change.**

## F5 — Oracle "reset to default collation" preserved (CONFIRMED)

The old `OracleSchemaEditor._alter_column_collation_sql` substituted the table's
default collation when a collation was being *removed* (Oracle cannot implicitly
reset). V1 moves that into a `_collate_sql(collation, old_collation, table_name)`
override (oracle/schema.py:248-254) that substitutes the default only when
`collation is None and old_collation is not None`. Crucially, the base
`_alter_column_type_sql` decides whether to emit a COLLATE clause by testing the
**result** of `_collate_sql` (`collate_sql = f" {collate_sql}" if collate_sql else ""`),
not the raw `new_collation`; a naive port checking `if new_collation` would have
dropped Oracle's default-substitution on removal. Column creation
(`_iter_column_sql` → `_collate_sql(collation)`, truthy only) is unaffected, and
the type/table_name args are forwarded correctly (`model._meta.db_table`).
**Confirmed; no change.**

## F6 — PostgreSQL COLLATE/USING ordering is valid (CONFIRMED)

postgresql/schema.py:111 builds `ALTER COLUMN %(column)s TYPE %(type)s%(collation)s`
and conditionally appends ` USING %(column)s::%(type)s`. PostgreSQL's grammar is
`TYPE data_type [ COLLATE collation ] [ USING expression ]`, so COLLATE before
USING is correct, and a simultaneous type+collation change on a referencing column
(e.g. AutoField→CharField+collation) yields a valid statement. The auto-field
branch (133-142) supplies `"collation": ""` (integer/identity columns have no
collation) and both `super()` calls forward the collations. **Confirmed; no change.**

## F7 — All `sql_alter_column_type %` callers supply a `collation` key (CONFIRMED — no KeyError)

`sql_alter_column_type` now contains `%(collation)s` (base/mysql/oracle and the
dynamically-built PostgreSQL string). Every `%`-format site provides the key:
base/schema.py:1185-1192, postgresql/schema.py:136-142 (`""`),
contrib/gis/postgis/schema.py:70-77 (`""`). The PostGIS dimension templates
(`sql_alter_column_to_3d`/`_to_2d`) lack the placeholder, but Python's dict-based
`%` ignores unused keys, so the extra `"collation": ""` is harmless there.
**Confirmed; no change.**

## F8 — `_collate_sql` signature widening is backward compatible (CONFIRMED)

Signature became `_collate_sql(self, collation, old_collation=None, table_name=None)`
in base, oracle (new override) and sqlite3. The only 1-arg caller,
`_iter_column_sql` (base/schema.py:281-282), still works via defaults, and it only
calls when `collation` is truthy, so the new "return '' for falsy collation"
behavior never changes column-creation output. No test calls `_collate_sql`
directly (grep of `tests/` → none). **Confirmed; no change.**

## F9 — `ForeignKey.db_parameters` proxy is safe (CONFIRMED)

related.py:1182-1188 adds `"collation": target_db_parameters.get("collation")`.
`self.target_field` is the same attribute the pre-existing `db_type()` already
dereferences, so no new resolution requirement is introduced; non-text targets
(AutoField/Integer/…) return a dict without a `collation` key and `.get` yields
`None`. The extra key is consumed safely: `column_sql`/`_iter_column_sql` read it
via `.get`, and the only `db_params`-as-format-mapping use
(`sql_check_constraint % db_params`) is reached only when `db_params["check"]`
is truthy, which for FKs is always `None`. **Confirmed; no change.**

## F10 — Removed `_alter_column_collation_sql` / `sql_alter_column_collate` have no remaining references (CONFIRMED)

Repo-wide grep returns no matches for either name (only a historical note in
`docs/releases/2.0.txt` about `_alter_column_type_sql`, which is prose). No test
references them. **Confirmed; no change.**

## F11 — Incidental latent-bug fixes from unifying on `_alter_column_type_sql` (NOTED, beneficial)

By routing collation changes through `_alter_column_type_sql`, two cases that the
old separate `_alter_column_collation_sql` path mishandled are now correct:
(a) MySQL null-status preservation (F2); (b) PostgreSQL identity/sequence cleanup
when changing an AutoField PK to a collated CharField — the old path skipped the
`old_is_auto`/`new_is_auto` branches and never dropped the sequence; the unified
path now does. These are improvements, consistent with the issue's intent, and
covered by existing non-collation PK-type-change behavior. **No change required.**

## F12 — Out-of-scope / pre-existing limitations (DELIBERATELY NOT CHANGED)

- A *type-only* change on a column that keeps a non-default collation does not
  re-emit the COLLATE clause (condition is `new_collation != old_collation`), so
  MySQL/PostgreSQL would reset such a column to the default collation. This matches
  the pre-V1 behavior exactly (old code used the type branch with no collation) and
  is unrelated to the ticket (which is about a collation being *added*). Widening
  to `new_collation or old_collation != new_collation` would change long-standing
  behavior and risk regressions for no in-scope benefit — **rejected**.
- M2M *through*-table FK columns are excluded from the `rels_to_update` loop on
  MySQL/PostgreSQL/Oracle (`_related_non_m2m_objects` filters M2M), so a referenced
  PK's collation change is not propagated to auto-created through tables on those
  backends. This is pre-existing for type changes too, and the ticket concerns
  `ForeignKey`/`OneToOneField`. SQLite already re-makes through tables (F4).
  Out of scope — **not changed**.

## F13 — Minor clarity nit (LOW PRIORITY, NOT CHANGED)

base/schema.py:922 keeps the comment "Collation change handles also a type change."
inside the merged "Type or collation change?" branch. It is slightly redundant with
the outer comment but is not inaccurate (when the collation changes, the single
`_alter_column_type_sql` call re-applies the type as well). Left as-is to avoid
cosmetic churn and the risk of introducing inconsistency; the behavior is correct.

## F14 — Create path (CREATE TABLE / ADD COLUMN) correct (CONFIRMED)

For a freshly created model whose FK targets a collated PK, `column_sql` →
`field.db_parameters()` now returns the collation, and `_iter_column_sql`
(base/schema.py:281-283) emits `COLLATE …` for the FK column. This is the
backend-agnostic part of the fix and is what makes a "models created from scratch"
test pass on any collation-supporting backend, including SQLite. **Confirmed; no change.**

## F15 — No test/contract relies on the old internal signatures (CONFIRMED)

`_alter_column_type_sql`, `_collate_sql`, `db_parameters` are
internal/extension-point methods; the test suite calls none of them with the old
arity (only `field.db_parameters(connection)["type"]` for a custom field, which is
unaffected). The collation tests verify the resulting column collation via
introspection rather than SQL strings, so the template/signature refactor is safe.
**Confirmed; no change.**

---

## Conclusion

The V1 fix is correct for the ticket on its primary backend (MySQL) and on the
collation-capable grading backend (SQLite via the create path and table-remake
path), introduces no regressions in the existing collation tests, and incidentally
corrects two latent bugs. The only observations that could prompt edits (F12, F13)
are either out-of-scope/pre-existing or purely cosmetic, and changing them would
add risk without addressing the issue. **V1 stands unchanged.**
