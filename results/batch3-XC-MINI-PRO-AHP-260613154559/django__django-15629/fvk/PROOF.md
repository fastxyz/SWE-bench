# PROOF — db_collation propagation to foreign keys (django__django-15629)

**Constructed, not machine-checked.** Symbolic reasoning over the mini-X SQL algebra
of `SPEC.md` §2, discharging the obligations of `PROOF_OBLIGATIONS.md`. No
`kompile`/`kprove` was run (environment has no toolchain — task constraint); §6 emits
the exact commands that would upgrade this to *machine-verified*.

---

## 1. What is proved (plain language)

For every foreign key `fk` whose target field carries a database collation `C`:

1. `fk.db_parameters(c)["collation"] == C` (and `type`/`check` unchanged) — **(FK-PARAMS)**.
2. Creating/adding a column for `fk` emits `… COLLATE quote(C)` — **(COLUMN-SQL)**.
3. When a referenced unique/PK field's **type or collation changes**, every
   referencing FK column is re-typed *with the new collation*, and this happens
   **between** dropping and re-creating the FK constraints — **(ALTER-FIELD)** +
   **(ALTER-TYPE)** + **(LOOP)**, ordering by **PO-7**.
4. On SQLite the same is achieved by re-making the referencing tables — **(SQLITE-REBUILD)**.
5. For every non-collation field the generated SQL is **identical to V0** — **PO-5**.

Together these entail the ticket's requirement: the `ADD CONSTRAINT … FOREIGN KEY`
between two columns that now share collation `C` is well-typed and succeeds on MySQL.

## 2. Function-level proof sketches

### (FK-PARAMS) — PO-1
`db_parameters` returns a literal dict. `type ↦ self.db_type(c)` and
`check ↦ self.db_check(c)` are the V0 bindings (FRAME). The added
`collation ↦ self.target_field.db_parameters(c).get("collation")` is a direct read
of the target's contract. The only dereference, `self.target_field`, is the *same*
one V0's `db_type` performed, so the domain (P1) is unchanged: no new partiality. ∎

### (ALTER-TYPE) — PO-2/PO-4, the heart of the fix
Symbolically execute `_alter_column_type_sql(model, of, nf, NT, Cold, Cnew)`:

- **Branch guard** `Cnew ≠ Cold`:
  - true ⇒ `collate := _collate_sql(Cnew, Cold, table)`; then
    `collate_sql := " " + collate` if `collate ≠ ""` else `""`.
  - false ⇒ `collate_sql := ""`.
- **SUBST** into `sql_alter_column_type` with holes `(column ↦ nf.column,
  type ↦ NT, collation ↦ collate_sql)`.

MySQL override first rewrites `NT := NT + nullStatus(of)` (`" NOT NULL"`/`" NULL"`
from the *old* field's `null`), then delegates. Composing for the **ticket** (lattice
B, MySQL), `Address.account` (O2O, `of.null = False`):
```
NT'        = "varchar(22)" + " NOT NULL"          = "varchar(22) NOT NULL"
collate    = _collate_sql("utf8_bin", None, addr) = "COLLATE `utf8_bin`"   (PO-2 base, B)
collate_sql= " COLLATE `utf8_bin`"
result     = "MODIFY `account_id` varchar(22) NOT NULL COLLATE `utf8_bin`"
```
and for `Profile.account` (FK, `of.null = True`) the same with `NULL`:
`"MODIFY `account_id` varchar(22) NULL COLLATE `utf8_bin`"`. Wrapped by
`sql_alter_column` these are **exactly** the two statements `PROBLEM.md` demands. ∎

Case C (`x,x`) yields no suffix — recorded as Finding **F4** (⚠️ in PO-4); case D
(`x,None`) yields `""` on MySQL/PG (reset) and the Oracle default via PO-2/PO-3
(Finding **F5**); case A yields `""` (PO-5).

### (ALTER-FIELD) — PO-7/PO-8 + (LOOP) PO-9
`drop_foreign_keys = supports_fks ∧ (pk∧pk ∨ uniq∧uniq) ∧ (oldType≠newType ∨ Cold≠Cnew)`.
When true the proof proceeds by Transitivity over the fixed statement order:
**drop constraints** (≈L835) → **own-column alter** (≈L917, via (ALTER-TYPE)) →
**rels loop** (≈L1032) → **recreate constraints** (≈L1067). The loop is discharged by
its circularity (PO-9): assuming `INV(k)`, the body reads `new_rel.field.db_parameters`
(collation = target's, by FK-PARAMS), `old_rel.field.db_parameters` (old collation),
calls (ALTER-TYPE), and `execute`s one wrapped statement on the distinct column
`new_rel.field.column`; earlier emissions are framed unchanged ⇒ `INV(k+1)`. At loop
exit every referencing column has been re-typed with its target collation. Since both
endpoints carry `C` *before* the recreate step (PO-7), the recreated constraint is
well-typed. ∎

### (COLUMN-SQL)/(SQLITE-REBUILD) — PO-6
`_iter_column_sql` yields `_collate_sql(C)` exactly under `if C :=`, so a created
column has the `COLLATE` clause iff `C ≠ None`; by FK-PARAMS the FK's `C` is the
target's. On SQLite, the alter is a table re-make whose guard now includes
`Cold ≠ Cnew`; `_remake_table(related)` regenerates the FK column through
`column_sql`, so the FK collation tracks the target **for every lattice case**
(B,C,D,E) — this is why F4 cannot manifest on SQLite. ∎

## 3. Discharging the verification conditions

- **Z3 / linear & structural:** PO-1, PO-3 (caller enumeration), PO-5 (template
  string equality with empty hole), PO-8 (empty relation set when unreferenced),
  PO-10 (finite list measure), PO-11 (arity/grep).
- **CASE over the collation lattice {A,B,C,D,E}:** PO-2, PO-4, PO-6 — each arm a
  finite SUBST; no nonlinear arithmetic arises (unlike the `sum` example there is no
  `/Int`, so no exact-halving `[simplification]` lemma is needed).
- **Coinduction / circularity:** PO-9, guarded by one genuine `execute` step per
  iteration; the "running accumulator" is the emitted-statement list, the
  no-aliasing fact (distinct columns) plays the role the disjointness side condition
  plays in the loop template.
- **VC-NULL (F3, pre-existing):** the nullability templates carry no `%(collation)s`;
  in the combined collation+nullability change the last `MODIFY` (the null action)
  omits `COLLATE`. The VC "final collation = new collation" therefore **fails** here
  for both V0 and V1 ⇒ surfaced as Finding F3, *not* admitted as proved.

## 4. No-regression argument (PO-5, expanded)

The fix is *conservative on the non-collation domain* (lattice A), which is the
overwhelming majority of schema operations:
- `%(collation)s` ↦ `""`, and `"MODIFY %(column)s %(type)s%(collation)s"` with an
  empty third hole is the *same string* as V0's `"MODIFY %(column)s %(type)s"`.
- `drop_foreign_keys` gains the disjunct `None != None = False` ⇒ unchanged.
- `_collate_sql(None,…) = ""`, only ever *called* with `None` from the new ALTER
  path; the legacy `_iter_column_sql` call stays guarded ⇒ CREATE SQL unchanged.
- `db_parameters` gains a `collation: None` entry consumed solely by a guarded `if`.

Hence no statement emitted for a non-collation field changes — the blast radius is
confined to columns that actually have (or reference) a collation. The one *intended*
behavioural change on the collation domain is that the field's-own collation change
on MySQL now keeps `NULL`/`NOT NULL` (V0 dropped it, silently nullifying the column —
a latent V0 bug the refactor removes); this is strictly more correct and invisible to
introspection-based tests.

## 5. Well-formedness audit (PO-11) — every touched site

| Site | Change | collation key supplied? |
|---|---|---|
| `base.sql_alter_column_type` | `+%(collation)s`; removed `sql_alter_column_collate` | n/a (template) |
| `base._alter_column_type_sql` | new sig `(…, old_collation, new_collation)`; computes `collate_sql` | yes |
| `base._alter_field` | compute `old/new_collation` once; disjunct in `drop_foreign_keys`; merged type/collation branch; rels loop passes collations | n/a |
| `base._alter_column_collation_sql` | **removed** | — (no callers) |
| `base._collate_sql` | new sig `(collation, old_collation=None, table_name=None)`; `""` for falsy | n/a |
| `mysql.sql_alter_column_type` | `+%(collation)s`; removed `sql_alter_column_collate` | n/a |
| `mysql._alter_column_type_sql` | new sig; forwards collations (after null-status) | via super |
| `oracle.sql_alter_column_type` | `+%(collation)s`; removed `sql_alter_column_collate` | n/a |
| `oracle._alter_column_type_sql` | new sig; forwards | via super |
| `oracle._alter_column_collation_sql` → `oracle._collate_sql` | replaced; default-collation-on-reset moved here | n/a |
| `postgresql._alter_column_type_sql` | new sig; template `+%(collation)s` before `USING`; auto-field branch `"collation":""`; super calls forward | yes (3 sites) |
| `postgis._alter_column_type_sql` | new sig; dim branch `"collation":""`; super forwards | yes |
| `sqlite3._alter_field` | rebuild guard `∨ Cold≠Cnew` | n/a |
| `sqlite3._collate_sql` | new sig (body unchanged) | n/a |
| `related.ForeignKey.db_parameters` | adds `collation` from target | n/a |

Grep confirms **no** remaining reference to `_alter_column_collation_sql` or
`sql_alter_column_collate`, and **every** `% {...}` against `sql_alter_column_type`
supplies a `collation` key (base, postgresql auto-field, postgis dim). ✅

## 6. Residual risk & the machine-check gate

- **Partial vs total correctness.** PO-9 is partial; termination (PO-10) is trivial
  (finite relation list) and offered as the recommended add-on.
- **Trusted base.** (i) adequacy of the mini-X SQL algebra vs. the real backends'
  SQL dialects (especially MySQL's "MODIFY without COLLATE resets to table default"
  rule, which the spec encodes as the motivation for emitting COLLATE); (ii) the
  reachability metatheory and `kprove`; (iii) the Z3/`[simplification]` oracle.
- **Constructed, not machine-checked.** To upgrade:

  ```sh
  kompile schema.k --backend haskell        # compile the mini-X SQL-synthesis fragment
  kast    --backend haskell schema-spec.k   # (optional) confirm the claims parse
  kprove  schema-spec.k                      # expected: #Top (all claims discharged)
  ```

  (The `.k` bodies are sketched in SPEC §2; writing them out fully is the roadmap
  step. Until `kprove` returns `#Top`, every ✅ here is "constructed".)

## 7. Test-redundancy recommendation (benefit 1) — **conditioned on machine-check**

This repository's tests are **fixed and hidden** and must not be modified, so this is
advisory only. *Were* the suite editable and the proof machine-checked:
- An introspection test asserting "FK column collation == target collation after a
  collated-PK alter/create" would be **subsumed** by (ALTER-FIELD)+(COLUMN-SQL) for
  every lattice case it instantiates (B/D/E for ALTER; B for CREATE).
- **Keep regardless:** (a) the F3 combined collation+nullability case (outside the
  contract — a real bug pin); (b) the F4 "type change, unchanged collation" case on
  MySQL/PG/Oracle (⚠️ in PO-4); (c) any backend-specific exact-SQL test; (d)
  termination/integration tests. Per the honesty gate, recommend **keeping all tests
  until `kprove` returns `#Top`.**
