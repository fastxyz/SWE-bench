# PROOF OBLIGATIONS — db_collation propagation to foreign keys

Each obligation is a verification condition (VC) the contracts of `SPEC.md`
generate. Discharge tier: **Z3** = linear/structural fact; **CASE** = finite case
split over the collation lattice `{None, x, y}` × `{change, no-change}`; **SUBST** =
template-substitution equality; **FRAME** = untouched cells/dicts carried unchanged.
Status legend: ✅ discharged (constructed); ⚠️ discharged *as a precondition* (not a
universal postcondition — see linked Finding); 🔒 capability-gated (machine-check).

The finite case lattice used throughout (the values of `(Cold, Cnew)`):
```
A: (None, None)   no collation anywhere      D: (x, None)   removed
B: (None, x)      added            (TICKET)   E: (x, y)      changed
C: (x, x)         unchanged                    (x ≠ y, both ≠ None)
```

---

## PO-1 — (FK-PARAMS) collation equals target's; type/check unchanged
**VC:** `∀ fk, c. fk.db_parameters(c) = {type: fk.db_type(c), check: fk.db_check(c),
collation: fk.target_field.db_parameters(c).get("collation")}`.
**Discharge:** SUBST on the literal dict in `related.py`; `db_type`/`db_check`
bindings are unchanged from V0 (FRAME). Precondition `target_field` resolvable (P1)
already required by `db_type`, so no new partiality (⚠️ → see PD2/F-none; actually a
clean ✅ since the domain is unchanged).
**Status:** ✅ (domain = P1, identical to V0's `db_type`).

## PO-2 — (COLLATE) base/Oracle return values over the lattice
**VC (base):** A,B,C,E with `C≠None` ⇒ `"COLLATE " + quote(Cnew)`; `Cnew=None`
(A,D-as-input) ⇒ `""`.
**VC (oracle):** D (`None`,`x`) ⇒ `"COLLATE " + quote(defaultColl(T))`; all other
shapes delegate to base.
**Discharge:** CASE over the lattice; each arm is a SUBST. The operator-precedence
reading `("COLLATE "+quote(C)) if C else ""` is the intended one (Python binds `+`
tighter than the conditional). 
**Status:** ✅.

## PO-3 — (COLLATE) Oracle default branch has a defined `table_name` (side condition)
**VC:** whenever Oracle's `_collate_sql` takes `collation=None ∧ old≠None`,
`table_name ≠ None`.
**Discharge:** the branch is reachable from exactly two callers:
(i) `_alter_column_type_sql` passes `model._meta.db_table` (never `None`);
(ii) `_iter_column_sql` calls `_collate_sql(collation)` only under `if collation :=`
(truthy), so `collation=None` is impossible there and the branch is not entered.
Hence the branch always has a real table. Z3 on the guard + caller enumeration.
**Status:** ✅ (PD3).

## PO-4 — (ALTER-TYPE) emitted SQL carries `COLLATE` iff collation changes to defined
**VC:** `alterTypeSql` emits a `COLLATE` suffix ⇔ `Cnew ≠ Cold ∧ effectiveColl ≠ ""`,
and the suffix names `Cnew` (base/MySQL/PG) or `defaultColl(table)` (Oracle reset).
**Discharge:** CASE over the lattice:
- A: `Cnew=Cold` ⇒ branch `collate_sql=""` ⇒ no suffix. ✅
- B (TICKET), E: `Cnew≠Cold`, base `_collate_sql≠""` ⇒ ` COLLATE quote(Cnew)`. ✅
- C: `Cnew=Cold` ⇒ no suffix (this is exactly **F4**). ⚠️ (universal postcondition
  fails for the "match the target" intent on MySQL/PG/Oracle ALTER path; holds on
  SQLite via PO-6). Linked: F4.
- D: `Cnew≠Cold`, base `_collate_sql=""` ⇒ no suffix on MySQL/PG (reset to default,
  correct); Oracle substitutes default (PO-2). ✅ for the chosen semantics (F5 notes
  the cross-table-default caveat).
**Status:** ✅ for A,B,D,E; ⚠️ C (F4).

## PO-5 — (NO-REGRESSION) non-collation paths are byte-identical to V0
**VC:** for fields with `collation=None` on both sides (lattice A), every CREATE/ADD/
ALTER statement equals the V0 output.
**Discharge:** (a) `%(collation)s` hole resolves to `""` (PO-4 arm A), and
`sql_alter_column_type` with an empty third hole equals the V0 two-hole template
string; (b) `drop_foreign_keys`'s new disjunct `old_collation != new_collation` is
`None != None = False`, leaving the condition = V0's `old_type != new_type`;
(c) `_collate_sql` returns `""` for falsy input, and is only *called* for `None` from
the new ALTER path (the old `_iter_column_sql` call is still guarded), so CREATE SQL
is unchanged; (d) `db_parameters` adds a `collation:None` key consumed only by
`_iter_column_sql`'s guarded `if`, so no new clause appears. SUBST + Z3.
**Status:** ✅ (PD4).

## PO-6 — (COLUMN-SQL)/(SQLITE-REBUILD) creation & rebuild always carry target collation
**VC:** with `db_parameters["collation"]=C≠None`, the generated column contains
`COLLATE quote(C)`; and on SQLite a referenced-field type/collation change re-makes
each referencing table, regenerating its FK column via the same path.
**Discharge:** `_iter_column_sql` yields `_collate_sql(C)` under `if C :=` ⇒ present
iff `C≠None` (CASE). For SQLite, the rebuild guard
`new_field.unique ∧ (oldType≠newType ∨ Cold≠Cnew)` fires on lattice B/D/E (and on a
pure type change), and `_remake_table(related)` rebuilds via `column_sql` ⇒ the FK
column collation tracks the target unconditionally (this is why **F4 cannot occur on
SQLite**). FRAME on the unrelated rebuild machinery.
**Status:** ✅.

## PO-7 — (ALTER-FIELD) drop-before / recreate-after ordering
**VC:** for `drop_foreign_keys` true, each referencing FK constraint is deleted
before any column alteration and re-created after all of them.
**Discharge:** by program order in `_alter_field`: constraint drop (≈L835–842) →
own-column alter (≈L917) → `rels_to_update` column alters (≈L1032–1056) → constraint
recreate (≈L1067–1072). No rule reorders these (sequential `self.execute`). Hence at
recreate time both endpoints already carry the matching collation ⇒ MySQL
`ADD CONSTRAINT` is well-typed. Transitivity over the statement sequence.
**Status:** ✅.

## PO-8 — (ALTER-FIELD) `drop_foreign_keys` fires on collation-only change without harm
**VC:** adding `old_collation != new_collation` to the guard never drops/recreates a
constraint that should be left alone, and for non-referenced fields is a no-op.
**Discharge:** the disjunct only *enables* the existing drop/recreate machinery,
which iterates `_related_non_m2m_objects` — **empty** for a field with no incoming
FKs (CASE: referenced vs not). For a referenced unique/PK field whose collation
changes, dropping+recreating the constraint is *required* on MySQL and safe
elsewhere (same machinery already used for type changes). Z3 on the guard + emptiness
of the relation set in the unreferenced case.
**Status:** ✅.

## PO-9 — (LOOP) `rels_to_update` invariant `INV(k) ⇒ INV(k+1)`
**VC:** processing relation `r_{k+1}` appends exactly
`wrap(alterTypeSql(r.col, r.newType, r.Cold, r.Cnew))` and mutates no earlier
emission; columns are pairwise distinct (no aliasing).
**Discharge:** guarded coinduction (the loop circularity): one genuine
`db_parameters`+`execute` step per iteration provides guardedness; the body writes a
fresh column name each time (distinct relations ⇒ distinct columns), so FRAME carries
prior emissions unchanged. Base case `k=0` is `INV(0)=E₀`. Bound `0≤k≤|rels|`.
**Status:** ✅ (partial correctness; termination = finite relation list, PO-10).

## PO-10 — (TERMINATION, recommendation only)
**VC:** the `rels_to_update` loop halts.
**Discharge:** the iterable is a finite materialised list
(`rels_to_update.extend(_related_non_m2m_objects(...))`); the measure `|rels| - k`
strictly decreases and is bounded below by 0. (Default kit mode is partial
correctness; this is offered as the recommended total-correctness add-on.)
**Status:** ✅ trivially (finite list); flagged as recommendation per kit default.

## PO-11 — Signature & template coherence (well-formedness)
**VC:** every call site of `_alter_column_type_sql`/`_collate_sql` matches the new
arities, and every `%`-format of `sql_alter_column_type` supplies a `collation` key.
**Discharge:** enumerated in PROOF §5 — base, mysql, oracle, postgresql, postgis
overrides + the two base call sites (own-column, rels loop) + postgresql auto-field
branch (`"collation": ""`) + postgis dim branch (`"collation": ""`). No residual
reference to the removed `_alter_column_collation_sql` / `sql_alter_column_collate`.
**Status:** ✅ (grep-verified, PROOF §5).

## PO-12 — Machine-check gate
**VC:** upgrade every ✅ above from *constructed* to *machine-verified*.
**Discharge:** run the `kompile`/`kprove` commands in PROOF §6.
**Status:** 🔒 not run in this environment (task constraint); recommendation only.
