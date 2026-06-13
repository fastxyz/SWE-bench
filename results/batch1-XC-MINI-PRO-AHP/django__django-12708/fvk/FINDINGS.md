# FINDINGS — plain language (`input → observed vs expected`)

Audit of the **V1 fix** (`alter_index_together` deletes with
`{'index': True, 'unique': False}`) for
[`django__django-12708`](../benchmark/PROBLEM.md). Each finding traces to an
obligation in [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

Legend: **[CONFIRMING]** supports keeping V1 · **[CORNER]** out-of-domain edge ·
**[OUT-OF-SCOPE]** real but not this bug.

---

## F1 — Root cause is an **asymmetry**: a unique constraint masquerades as an index, but never vice-versa  **[CONFIRMING]** (OB2, OB4, OB7)

- **input:** a 2-field model with `unique_together = [(a,b)]` **and**
  `index_together = [(a,b)]`; run a migration that drops the `index_together`, on
  MySQL or SQLite.
- **observed (pre-fix):** `ValueError: Found wrong number (2) of constraints …`.
  `_constraint_names(..., index=True)` matched **both** the `_idx` index *and* the
  `_uniq` constraint, because those backends report a unique constraint with
  `index=True` (MySQL `SHOW INDEX` / SQLite `PRAGMA index_list`).
- **expected:** drop the one non-unique `_idx` index; leave the unique constraint.
- **root cause:** the filter `{'index': True}` is ambiguous in **one direction
  only**. A unique constraint can have `index=True`, but an `index_together` index
  *never* has `unique=True`. So the index-deletion filter could over-match; the
  unique-deletion filter `{'unique': True}` could not. **V1 adds `unique=False`
  precisely to the one ambiguous direction.** This is the central justification for
  both *what* V1 changes and *what it leaves alone*.

## F2 — The fix is **monotone**: it can only shrink the match set, never grow it  **[CONFIRMING]** (OB5)

- **input:** any table/columns reaching `alter_index_together`'s deletion.
- **observed:** `matches(C, idxFilter) → matches(C, idxFilterV0)`, so V1's matched
  set is a **subset** of the pre-fix set; it differs only by dropping `unique=True`
  rows.
- **expected / consequence:** V1 cannot introduce a *new* "too many constraints"
  crash. Where the old code matched 1 (PostgreSQL, or no unique_together) V1 still
  matches that same 1; where it matched 2 (the bug) V1 matches 1. No regression is
  possible by construction.

## F3 — V1 removes **exactly** the spurious unique-constraint match  **[CONFIRMING]** (OB1, OB2)

- **input:** the bug scenario, any backend (`IU` symbolic).
- **observed:** `cnames(CS, (a,b), {'index':True,'unique':False}, EXCL) =
  {name_idx}` — size 1 on MySQL, SQLite **and** PostgreSQL.
- **expected:** size 1, dropping `_idx`. ✓ The fix is correct and **backend-uniform**
  (it also leaves the already-working PostgreSQL path unchanged).

## F4 — The symmetric direction was already safe; **correctly left untouched**  **[CONFIRMING]** (OB3, OB4)

- **input:** same model, drop the `unique_together`, keep `index_together`.
- **observed:** `_constraint_names(..., unique=True)` matches only the unique
  constraint; the `_idx` index has `unique=False` and is excluded → size 1, no
  crash — on every backend.
- **expected:** drop the unique constraint only. ✓ **No change to
  `alter_unique_together` is warranted**; editing it would be unjustified scope
  creep (nothing in the obligations requires it).

## F5 — **[CORNER / pre-existing]** `unique_together` on the primary-key columns  (OB: OUT-OF-DOMAIN)

- **input:** a (degenerate) model whose `unique_together` columns are *exactly* the
  primary-key columns, then drop that `unique_together`, on MySQL/PostgreSQL (where
  the PK has `unique=True`).
- **observed (today, independent of this fix):** `_constraint_names(..., unique=True)`
  could match **both** the PK and the unique constraint → potential
  `Found wrong number (2)`.
- **expected:** drop only the unique constraint.
- **status:** **pre-existing and orthogonal** — not reachable from the issue's
  scenario (unique_together on non-PK fields), not affected by V1 (which only edits
  the index path), and degenerate (unique_together on the PK is redundant). **Not
  fixed here**; recorded for a future hardening pass (see ITERATION_GUIDANCE).

## F6 — **[OUT-OF-SCOPE]** issue point 2: moving an index declaration re-creates the index  (OB: OUT-OF-SCOPE)

- **input:** refactor `index_together = [(a,b)]` into `Meta.indexes =
  [Index(fields=['a','b'])]` (the reporter's actual goal — "not deleting the index,
  just the way it is declared").
- **observed:** the autodetector emits `AddIndex` + `AlterIndexTogether`(remove), so
  the index is dropped and re-created even though it is logically the same index.
- **expected (reporter's wish):** recognize the move and emit no DDL.
- **status:** this is a **migration-autodetector / optimizer** behavior, not a
  schema-editor cardinality bug. It causes churn, **not a crash**. With V1 the
  removal half no longer crashes (the new Meta index is name-excluded, so deletion
  still resolves to the single old `_idx`; OB6). Genuinely improving the *move* is a
  separate enhancement and **out of scope** for this fix. Recorded as feedback.

## F7 — **[CONFIRMING / positive]** V1 also closes a latent **silent wrong-deletion**  (OB8)

- **input:** the `_idx` index is already gone (DB drift / manual edit), only the
  unique constraint remains, and a migration tries to drop the `index_together`, on
  MySQL/SQLite.
- **observed (pre-fix):** `{'index':True}` matches the unique constraint
  (`index=True`) → size 1 → `DROP INDEX` **silently destroys the unique
  constraint** — a wrong, data-integrity-affecting deletion.
- **observed (V1):** `{'index':True,'unique':False}` matches nothing → size 0 →
  `ValueError` — a safe, loud failure that touches no constraint.
- **expected:** never silently drop a *unique* constraint while asked to drop an
  *index*. ✓ V1 is strictly safer; this is a bonus beyond fixing the crash.

## F8 — **[CORNER]** assumption: at most one non-excluded non-unique composite index per column tuple  (OB: OUT-OF-DOMAIN)

- **input (hypothetical):** two distinct non-unique indexes over the identical
  ordered column tuple `(a,b)`, neither in `Meta.indexes`.
- **observed:** `cnames(..., idxFilter, ...)` would have size 2 → `ValueError`.
- **status:** Django's `index_together` de-dupes by column tuple, so it cannot
  auto-generate this; it would require hand-written DDL. **Out of domain**, recorded
  as an explicit assumption behind OB2, not a defect in V1.

---

## Spec-difficulty signal (benefit 2)

Writing the spec was **easy and clean** — the contract is a single set-cardinality
equation, and the one precondition that mattered (`unique=False` for the index
filter) is exactly the V1 change. **A clean spec writing itself onto the fix is
positive evidence the fix targets the real root cause** (the kit's converse of
"spec-difficulty = bug signal"). The only awkwardness was enumerating the
backend-dependent `IU`, which the proof then discharged *uniformly* (the result is
independent of `IU`) — further evidence the fix is robust across backends.

---

## Proof-derived findings from `/verify`

- **OB2/OB4 (uniqueness) hinge on (INV-U)/(INV-I)** — "the unique constraint is
  unique; the index_together index is non-unique". These are guaranteed by the
  *creation* paths (`_create_unique_sql` vs `_create_index_sql(suffix="_idx")`), not
  by the deletion code. **Classification:** confirmed invariant, no code change.
  **Next-iteration note:** if a future change ever made `index_together` build a
  unique index, OB2 would break — keep the creation/deletion symmetry under test.
- **F5 (PK collision)** — **Classification:** pre-existing latent bug, needs-guard,
  out of this issue's scope. **UltimatePowers question:** "Should `_delete_composed_index`
  also exclude `primary_key=True` (and check) constraints when resolving a
  unique/index to drop?" **Recommended next change:** consider passing
  `primary_key=False` on the unique path, or post-filtering, in a separate ticket.
- **F6 (declaration move)** — **Classification:** underspecified intent /
  autodetector behavior. **UltimatePowers question:** "When an index declaration
  moves between `index_together` and `Meta.indexes` with identical columns, should
  the autodetector emit no DDL?" **Recommended next change:** autodetector/optimizer
  work, not schema editor — separate ticket.
- **Tests:** see [`PROOF.md`](PROOF.md) §9 — recommendation-only, conditioned on
  `kprove` returning `#Top`; keep all tests meanwhile (the suite is fixed/hidden
  here anyway).
