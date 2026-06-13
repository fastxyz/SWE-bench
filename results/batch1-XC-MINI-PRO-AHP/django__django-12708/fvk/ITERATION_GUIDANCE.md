# ITERATION GUIDANCE — next-pass feedback

Distilled from [`FINDINGS.md`](FINDINGS.md) / [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)
/ [`PROOF.md`](PROOF.md). The evidence package for a subsequent code-generation pass.

## Verdict for THIS pass: **CONFIRM V1 — no source edit**

The audit discharged every in-domain obligation (OB1–OB8). The V1 change
(`alter_index_together` deletes with `{'index': True, 'unique': False}`) is:

- **correct & backend-uniform** — resolves to exactly the non-unique `_idx` on
  MySQL, SQLite, and PostgreSQL (F3, OB1/OB2);
- **minimal & targeted** — it patches the *only* ambiguous direction (F1); the
  symmetric `alter_unique_together` path is provably already exactly-one (F4,
  OB3/OB4), so it is correctly left untouched;
- **monotone / regression-free** — the added flag can only shrink the match set
  (F2, OB5);
- **a net safety gain** — it also closes a latent silent wrong-deletion under DB
  drift (F7, OB8).

No obligation motivates changing the source. Editing `alter_unique_together`, or
refactoring `_delete_composed_index`, would be **unjustified scope creep** against
the findings. **V1 stands unchanged.**

## Deferred items (separate tickets, NOT this issue)

1. **F5 — `unique_together` on PK columns.** A future hardening pass could make
   `_delete_composed_index` exclude `primary_key=True` (and `check=True`)
   constraints when resolving a unique/index to drop, so a `unique_together`
   declared on the PK columns cannot collide with the PK. Pre-existing, orthogonal,
   degenerate; out of scope here.
   - *UltimatePowers question:* "Should unique/index resolution always exclude PK
     and check constraints?"

2. **F6 — declaration move re-creates the index (issue point 2).** The reporter's
   real goal was to move an index from `index_together` to `Meta.indexes` without
   DDL churn. That is **migration-autodetector / optimizer** work
   (`django/db/migrations/`), not the schema editor. With V1 the move no longer
   *crashes*; eliminating the redundant drop+create is a distinct enhancement.
   - *UltimatePowers question:* "When an index's columns are unchanged but its
     declaration moves between `index_together` and `Meta.indexes`, should the
     autodetector emit no operations?"

3. **F8 — multiple non-unique composite indexes on identical columns.** Out of
   domain (Django can't auto-generate it). If ever supported, OB2's uniqueness would
   need the resolution to disambiguate by index *name/suffix*, not just flags.

## Invariant to protect (regression guard for the future)

OB2/OB4 depend on **(INV-I)**: `index_together` creates a *non-unique* index
(`_create_index_sql(..., suffix="_idx")`) and `unique_together` a *unique*
constraint. Keep the creation/deletion symmetry intact — if a future refactor made
`index_together` build a unique index, the `{'index':True,'unique':False}` filter
would stop matching it (size 0) and break. A test pinning "index_together index is
non-unique" protects the fix.

## Machine-check to upgrade "constructed" → "verified"

```sh
kompile schema_index.k --backend haskell
kast    --backend haskell schema_index-spec.k
kprove  schema_index-spec.k          # expected: #Top  (all 5 claims)
```

Only after `#Top` should the test-redundancy recommendation in [`PROOF.md`](PROOF.md)
§9 be acted on. Until then: keep all tests (the suite is fixed/hidden here regardless).
