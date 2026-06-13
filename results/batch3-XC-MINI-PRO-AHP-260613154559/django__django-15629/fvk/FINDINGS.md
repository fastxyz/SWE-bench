# FINDINGS — db_collation propagation to foreign keys (django__django-15629)

Plain-language findings, each as `input → observed vs expected`. Findings F1–F2 are
the **root-cause bugs the V1 fix removes**; F3–F6 are corners the act of specifying
surfaced (pre-existing and/or out of the ticket's scope — kept as findings, not
silently "fixed"); F7 is a positive finding; the proof-derived section is appended
from `/verify`.

The Findings report does **not** depend on machine-checking and is stated with full
confidence (per the honesty gate).

---

## F1 — `ForeignKey.db_parameters()` dropped the target's collation (ROOT CAUSE, fixed)

- **input:** FK `account` → `Account.id` where `Account.id` is
  `CharField(db_collation="utf8_bin")`; call `account.db_parameters(conn)`.
- **observed (V0):** `{"type": "varchar(22)", "check": None}` — **no `collation`
  key**, so `column_sql`/`_iter_column_sql` (which already honour
  `field_db_params["collation"]`) had nothing to emit and the FK column was created
  collation-less.
- **expected:** `{… , "collation": "utf8_bin"}` mirroring the target field.
- **fix:** `ForeignKey.db_parameters` now proxies
  `self.target_field.db_parameters(conn).get("collation")`
  (`django/db/models/fields/related.py`). Satisfies contract **(FK-PARAMS)**.

## F2 — `_alter_field` never carried collation onto referencing columns (ROOT CAUSE, fixed)

- **input:** migrate `Account.id` `BigAutoField → CharField(db_collation="utf8_bin")`
  while `Address.account` (O2O, NOT NULL) and `Profile.account` (FK, NULL) reference it.
- **observed (V0):** the `rels_to_update` loop re-typed the FK columns with
  `_alter_column_type_sql` which emitted **type only**:
  `MODIFY \`account_id\` varchar(22) NOT NULL` — no `COLLATE` — so the subsequent
  `ADD CONSTRAINT … FOREIGN KEY` failed on MySQL. Collation was handled by a
  *separate* method (`_alter_column_collation_sql`) used only for the field's own
  column, and that method also dropped MySQL's `NULL`/`NOT NULL`, so it could not be
  reused for FK columns.
- **expected:** `MODIFY \`account_id\` varchar(22) NOT NULL COLLATE \`utf8_bin\``
  and `… varchar(22) NULL COLLATE \`utf8_bin\``.
- **fix:** collation folded into the single `_alter_column_type_sql` path (new
  `old_collation`/`new_collation` parameters, `%(collation)s` added to
  `sql_alter_column_type`, `sql_alter_column_collate`/`_alter_column_collation_sql`
  removed); the `rels_to_update` loop now passes the FK's old/new collation; the
  MySQL override keeps `NULL`/`NOT NULL`. Verified to emit **exactly** the ticket's
  desired SQL (PROOF §3). Satisfies **(ALTER-TYPE)**, **(ALTER-FIELD)**.

## F3 — Simultaneous collation **and** nullability change loses the collation on MySQL (PRE-EXISTING, out of scope)

- **input (MySQL):** alter a *non-FK* `CharField(db_collation="x", null=False)`
  → `CharField(db_collation="y", null=True)`.
- **observed (V0 *and* V1):** two statements run — `MODIFY col varchar NOT NULL
  COLLATE y` then the nullability action `MODIFY col varchar NULL` (template
  `sql_alter_column_null = "MODIFY %(column)s %(type)s NULL"`, **no `%(collation)s`**).
  The second `MODIFY` omits `COLLATE`, so MySQL resets the column to the table's
  default collation — `y` is lost.
- **expected:** final collation `y`.
- **classification:** pre-existing latent bug in the *nullability* SQL templates,
  **not** introduced by V1 (V0 reached the same end state — PROOF §4, VC-NULL), and
  **not** the ticket's scenario. The ticket's FK columns never change nullability in
  the same operation (only the referenced PK changes), so the `rels_to_update` path
  is unaffected. **Decision: do not fix** (minimal-change rule; fixing means adding
  collation to `sql_alter_column_{null,not_null}`, an unrelated refactor). Recorded
  for the next iteration (ITERATION_GUIDANCE Q1).

## F4 — Type change with **unchanged** collation does not re-emit `COLLATE` on the ALTER path (RESIDUAL, narrow)

- **input (MySQL):** referenced PK `CharField(db_collation="x", max_length=10)` →
  `CharField(db_collation="x", max_length=20)`; FK column re-typed via `rels_to_update`.
- **observed (V1):** `Cold == Cnew == "x"`, so `_alter_column_type_sql` takes the
  no-collation branch and emits `MODIFY \`fk\` varchar(20) NOT NULL` — MySQL resets
  the FK column to the table default collation, which may not equal `x` ⇒ FK
  constraint mismatch.
- **expected (ideal):** `… varchar(20) NOT NULL COLLATE \`x\``.
- **classification:** **narrower** than the original bug (V0 *never* emitted a FK
  collation; V1 emits it whenever the collation *changes*, which is the ticket's
  case). The residual gap is "type changes but collation stays". It mirrors V0's own
  field-own-column behaviour (`elif type changed:` also never re-emitted collation),
  so it is consistent with the established convention and almost certainly shared by
  the upstream approach. **Fully absent on SQLite** (the rebuild path regenerates
  every column via `column_sql`, which *always* emits the collation from
  `db_parameters` — contract (COLUMN-SQL)). **Decision: do not fix** — it is not the
  ticket's scenario, and "always emit collation on every type change" would alter a
  large amount of unrelated `ALTER` output and risk regressions. Recorded as
  ITERATION_GUIDANCE Q2.

## F5 — Oracle collation *removal* on a FK column uses the FK table's default (EDGE, Oracle-only)

- **input (Oracle):** referenced PK loses its collation (`Cold = "x" → Cnew = None`);
  FK column re-typed via `rels_to_update`.
- **observed (V1):** Oracle's `_collate_sql(None, "x", fk_table)` substitutes
  `defaultColl(fk_table)` (Oracle cannot reset to default implicitly), emitting
  `MODIFY fk_col … COLLATE <fk_table_default>`. If the FK table and PK table have
  different default collations, the two columns may still differ.
- **classification:** deep Oracle-specific corner in the **reverse** of the ticket
  (removing, not adding, a collation). V0 did not propagate collation to FK columns
  at all, so V1 is **no worse and usually better**. The Oracle default substitution
  is faithfully migrated from V0's `_alter_column_collation_sql` (same
  `_get_default_collation` call), so behaviour for the field's *own* column is
  unchanged. **Decision: keep** (preserves V0 semantics; reverse-direction, not the
  ticket). ITERATION_GUIDANCE Q3.

## F6 — Propagation requires fresh referenced-field state (precondition P2)

- **input:** a caller alters a referenced PK by constructing a new field object and
  calling `editor.alter_field(Model, old, new)` **without** updating
  `Model._meta.pk` (so the FK's cached `target_field` still points at the old PK).
- **observed:** `new_rel.field.db_parameters["collation"]` (ALTER path) and the
  SQLite rebuild's `column_sql` resolve `target_field` to the **stale** PK, so the
  FK column may not pick up the new collation.
- **expected:** under normal migration execution the `to_state` model carries the
  new PK, so `target_field` is fresh and propagation is correct; likewise for
  create-from-scratch.
- **classification:** **precondition, not a code bug** (P2 in SPEC §4). The same
  staleness already governs FK column *type* propagation in V0 (the `rels_to_update`
  loop reads `new_rel.field.db_parameters["type"]`), so the fix introduces no new
  assumption. UltimatePowers question in ITERATION_GUIDANCE Q4.

## F7 — Backend collation-support check transitively covers the FK column (POSITIVE)

- **input:** target `CharField(db_collation=…)` on a backend lacking
  `supports_collation_on_charfield`.
- **observed:** `CharField._check_db_collation` / `TextField._check_db_collation`
  raise `fields.E190` on the *target*; the FK column is the same textual type, so no
  separate FK-level check is needed and none was added.
- **classification:** positive — the existing guard *enforces* precondition P3 for
  the FK column for free (the input-guard-as-precondition pattern from `formalize.md`).

---

## Proof-derived findings (from `/verify`) — see PROOF.md

- **PD1 (capability, not code):** the artifacts are **constructed, not
  machine-checked** — `kompile`/`kprove` are not run here. All "proved" results are
  conditioned on running the emitted commands (PROOF §6). Not a code defect.
- **PD2 (discharged side condition → confirms P1):** (FK-PARAMS) needs
  `target_field` resolvable; discharged because `db_type` (already in the returned
  dict) shares that precondition — the fix widens nothing. (PO-1.)
- **PD3 (discharged side condition → Oracle table-name):** the Oracle `_collate_sql`
  default branch needs a non-null `table_name`; discharged because the only caller
  that reaches the branch (`_alter_column_type_sql`) always supplies
  `model._meta.db_table`, and `_iter_column_sql` passes only truthy collations so
  never reaches it. (PO-3.)
- **PD4 (no-regression obligation discharged):** for every non-collation field
  (`collation == None` on both sides) the new `%(collation)s` hole is `""` and the
  collation branch of `drop_foreign_keys` is inert, so all non-collation ALTER/CREATE
  SQL is byte-for-byte identical to V0. (PO-5.)
