# SPEC — db_collation propagation to foreign keys (django__django-15629)

**Status:** constructed, **not** machine-checked. The K toolchain is not run in
this environment (per task constraints); the `.k` fragments below are written as
artifacts and reasoned about by hand, exactly as the FVK MVP prescribes.

This spec formalizes the **intended behaviour** of the V1 fix and checks the code
against it. Per `formalize.md` it is written in *intent-spec mode*: intent (the
ticket) ↔ code (the schema editor + `ForeignKey`) ↔ formal contract, and any
divergence becomes a Finding in `FINDINGS.md`.

---

## 1. Intent (from `benchmark/PROBLEM.md`)

A referenced column carrying a database collation (`CharField`/`TextField`
`db_collation`) must have that collation **mirrored onto every foreign-key column
that references it**, so that a MySQL `ADD CONSTRAINT … FOREIGN KEY` between them
succeeds (MySQL requires the referencing and referenced columns to share a
collation). Concretely, altering `Account.id` from `BigAutoField` to a collated
`CharField` must emit

```sql
ALTER TABLE `b_manage_address` MODIFY `account_id` varchar(22) NOT NULL COLLATE `utf8_bin`;
ALTER TABLE `b_manage_profile` MODIFY `account_id` varchar(22) NULL COLLATE `utf8_bin`;
```

(not the collation-less `MODIFY … varchar(22) NOT NULL`), and these must run
**between** dropping and re-creating the FK constraints.

---

## 2. mini-X semantics (the fragment the code actually uses)

The target is not an arithmetic loop but **SQL-string synthesis**. The faithful
"mini-X" is a tiny string/record algebra; it would be written as `schema.k` with:

```
// ----- sorts -----
//   Coll   ::= None | collation-name (an opaque token)
//   Params ::= { type: String, check: String|None, collation: Coll }   // db_parameters() result
//   Frag   ::= ( String , ParamList )                                  // (sql, bind-params)
//
// ----- _collate_sql(C, Cold, T) : String  (base) -----
rule collateSql(C, _, _)        => "COLLATE " +String quote(C)   requires C =/=K None
rule collateSql(None, _, _)     => ""                                            // base
//   Oracle override:
rule collateSqlOracle(None, Cold, T) => collateSql(defaultColl(T), Cold, T)  requires Cold =/=K None
rule collateSqlOracle(C, Cold, T)    => collateSql(C, Cold, T)               requires notBool (C ==K None andBool Cold =/=K None)

// ----- the COLLATE suffix used inside an ALTER … TYPE … -----
rule alterCollate(Cnew, Cold, T) => " " +String collateSql(Cnew, Cold, T)
        requires Cnew =/=K Cold andBool collateSql(Cnew,Cold,T) =/=String ""
rule alterCollate(Cnew, Cold, T) => ""
        requires Cnew ==K Cold orBool collateSql(Cnew,Cold,T) ==String ""

// ----- _alter_column_type_sql(col, NEWTYPE, Cold, Cnew) : Frag  (base) -----
rule alterTypeSql(col, NT, Cold, Cnew)
       => ( subst(sql_alter_column_type, col, NT, alterCollate(Cnew,Cold,table)) , .Params )
//   MySQL override prepends the *old* nullability to NT before delegating:
rule alterTypeSqlMySQL(col, NT, F, Cold, Cnew)
       => alterTypeSql(col, NT +String nullStatus(F), Cold, Cnew)
```

`sql_alter_column_type` is a backend template with **three** holes
`%(column)s %(type)s %(collation)s` (base: `ALTER COLUMN … TYPE …`; MySQL/Oracle:
`MODIFY …`; PostgreSQL: same plus a trailing `USING …::%(type)s`). `quote` is the
backend identifier quoter (back-ticks on MySQL). `nullStatus(F)` is `" NOT NULL"`
if `F.null` is false else `" NULL"` (MySQL only). This fragment is small and
faithful; nothing else in the code is touched by the fix.

The "loop" in scope is `_alter_field`'s `for old_rel, new_rel in rels_to_update`
iteration over the relations that reference the altered field; its invariant is in
§5.

---

## 3. Function contracts (reachability rules `φ_pre ⇒ φ_post`)

Uppercase = logical values; lowercase = program objects.

### (FK-PARAMS) `ForeignKey.db_parameters`
```
requires  f is a (resolved) ForeignKey/OneToOneField, c a connection
⇒ f.db_parameters(c) == { "type":  f.db_type(c),
                          "check": f.db_check(c),               // == None for FK
                          "collation": f.target_field.db_parameters(c).get("collation") }
```
i.e. the FK's column parameters equal the target field's, in particular the
**collation is exactly the referenced field's collation** (`None` when the target
is non-textual). Precondition: the relation is resolvable (the same precondition
`db_type` already required, since it dereferences `target_field`).

### (COLLATE) `_collate_sql(C, Cold, T)`
```
base:    requires ⊤  ⇒  result == ("COLLATE " + quote(C))   if C ≠ None
                       == ""                                  if C == None
oracle:  requires ⊤  ⇒  result == ("COLLATE " + quote(defaultColl(T)))  if C == None ∧ Cold ≠ None
                       == base(C,Cold,T)                                  otherwise
```
Side condition for the Oracle branch: `T` (table name) is non-null **whenever**
`C == None ∧ Cold ≠ None`. (Discharged in PROOF: that branch is reached only from
`_alter_column_type_sql`, which always passes `model._meta.db_table`; the
`_iter_column_sql` caller passes only truthy `C`, so the branch is not taken
there. — PO-3.)

### (ALTER-TYPE) `_alter_column_type_sql(model, of, nf, NT, Cold, Cnew)`
```
requires  ⊤
⇒  fragment sql == subst(sql_alter_column_type, nf.column, NT', S)   where
      NT' = NT             (base/PG/Oracle)   |  NT + nullStatus(of)  (MySQL)
      S   = " " + _collate_sql(Cnew,Cold,table)   if Cnew ≠ Cold ∧ _collate_sql ≠ ""
          = ""                                      otherwise
```
**Postcondition of interest:** the emitted column alteration carries a `COLLATE`
clause **iff** the collation changes to a defined value (or, on Oracle, is being
reset, where the explicit default is emitted), and the clause names exactly
`Cnew` (base/MySQL/PG) or the table default (Oracle reset).

### (ALTER-FIELD) `_alter_field(model, of, nf, …)` — propagation contract
```
requires  supports_foreign_keys ∧ ((of.pk ∧ nf.pk) ∨ (of.unique ∧ nf.unique))
          ∧ (oldType ≠ newType  ∨  Cold ≠ Cnew)        // = drop_foreign_keys
⇒  for every relation r referencing the field:
       (a) r's FK constraint is DROPPED before, and RE-CREATED after, the column
           alterations, and
       (b) r's FK column is altered via (ALTER-TYPE) to (newRelType, relCold→relCnew),
           where relCnew == nf-side target collation.
```
Where `Cold = of.db_parameters(c)["collation"]`, `Cnew = nf.db_parameters(c)["collation"]`.

### (COLUMN-SQL) creation path — `column_sql`/`_iter_column_sql`
```
requires  field f with f.db_parameters(c)["collation"] = C
⇒  the generated column definition contains "COLLATE quote(C)"  iff C ≠ None.
```
Because (FK-PARAMS) gives an FK the target's collation, **creating** a table or
adding a column with an FK to a collated field emits the matching `COLLATE`.

### (SQLITE-REBUILD) `sqlite3.DatabaseSchemaEditor._alter_field`
```
requires  nf.unique ∧ (oldType ≠ newType ∨ Cold ≠ Cnew)
⇒  every related model whose FK targets nf is re-made; each re-made FK column is
   regenerated by (COLUMN-SQL), hence carries the target collation.
```

---

## 4. Global precondition (the domain the contracts hold on)

- **P1 — relation resolved.** `f.target_field` is resolvable (related model loaded,
  `to_field`/`pk` known). Outside this domain `db_parameters` raises, exactly as
  `db_type` already did; not weakened by the fix.
- **P2 — state freshness.** In (ALTER-FIELD)/(SQLITE-REBUILD) the FK's
  `target_field` must reflect the *new* referenced field. This holds for migration
  execution (the `to_state` model carries the new PK) and for create-from-scratch.
  It does **not** hold if a caller mutates a field object but leaves the referenced
  model's `_meta.pk` stale (see Finding F6).
- **P3 — backend supports collation on the column type.** Enforced upstream by
  `CharField._check_db_collation` / `TextField._check_db_collation` on the *target*;
  the FK column is the same textual type, so the check transitively covers it
  (Finding F7, positive).

---

## 5. Loop invariant for the `rels_to_update` iteration (circularity)

Generalised over the iteration index `k` (relations processed) and the accumulated
emitted statements `E`:

```
INV(k):  after processing the first k relations r₁..r_k,
         E = E₀ ++ [ wrap(alterTypeSql(rᵢ.col, rᵢ.newType, rᵢ.Cold, rᵢ.Cnew)) | i ← 1..k ]
         ∧ each rᵢ.Cnew == (rᵢ.new target field collation)
         ∧ no rᵢ.FK-constraint exists yet (all dropped earlier; recreated after the loop)
Side condition:  0 ≤ k ≤ |rels_to_update|.
```

The loop body does exactly one `alterTypeSql` emission per relation and never
touches earlier ones (no aliasing — each relation has a distinct column), so
`INV(k) ⇒ INV(k+1)`; at `k = |rels_to_update|` every referencing column has been
re-typed with its target collation. This is the additive-accumulator shape of the
`(LOOP)` reference example, with "running sum" replaced by "list of emitted
ALTERs". Guardedness: each step performs one genuine `db_parameters`+emit
transition before the next.

---

## 6. What a clean spec being writable tells us

A clean contract **was** writable for the fix's domain (collation added or
changed), which is the positive signal that the core behaviour is well-defined. The
*difficulty* points — where a clean universal postcondition could **not** be
written without a side condition — are recorded as Findings F3–F6 (they are the
"spec-difficulty = bug signal" cases, all pre-existing or out-of-scope corners,
none of them the ticket's scenario).
