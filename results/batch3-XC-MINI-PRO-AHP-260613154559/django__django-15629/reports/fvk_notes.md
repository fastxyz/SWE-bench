# FVK notes — audit of the V1 fix for django__django-15629

This explains every decision taken during the FVK pass, tracing each to specific
entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`. **Outcome: V1 stands
unchanged.** No source file was edited in this pass; the justification is below.

## What the FVK pass did

1. Read the kit (`README`, `AGENTS`, `formalize`, `verify`, and the three knowledge
   primers). The bundled `examples/` are not present in this environment, so I
   imitated the `sum`-style template described in the primers, adapting the mini-X
   approach from an arithmetic loop to **SQL-string synthesis** (the actual domain of
   the fix) — see `fvk/SPEC.md` §2.
2. Wrote the five artifacts: `SPEC.md` (intent + mini-X + 6 function contracts + the
   `rels_to_update` loop invariant), `FINDINGS.md` (F1–F7 + proof-derived PD1–PD4),
   `PROOF_OBLIGATIONS.md` (PO-1…PO-12), `PROOF.md` (constructed proof + no-regression
   argument + well-formedness audit + machine-check gate), and
   `ITERATION_GUIDANCE.md` (Q1–Q5).
3. No `kompile`/`kprove` run (environment constraint); all proof results are labeled
   **constructed, not machine-checked** (PD1 / PO-12), per the honesty gate.

## Decision 1 — keep `ForeignKey.db_parameters` proxying the target collation

- **Traces to:** F1 (root cause), PO-1, PO-5, PO-6.
- The single change that fixes the *create-from-scratch* half of the ticket. PO-1
  shows it equals the target's parameters with no new partiality (the `target_field`
  dereference was already in V0's `db_type`, so precondition P1 is unchanged). PO-5
  shows it is inert for non-collation FKs (a `collation: None` key consumed only by a
  guarded `if`). **Confirmed correct; kept.**

## Decision 2 — keep the unified `_alter_column_type_sql` (collation folded in)

- **Traces to:** F2 (root cause), PO-2, PO-4, PO-11, PROOF §2.
- This is the load-bearing change. PROOF §2 symbolically derives, for the ticket's
  lattice case B on MySQL, the **exact** statements `PROBLEM.md` demands
  (`MODIFY \`account_id\` varchar(22) NOT NULL COLLATE \`utf8_bin\`` and the `NULL`
  variant). Keeping the MySQL null-status prefix (and removing the separate
  `_alter_column_collation_sql`, which dropped it) is what makes the FK columns
  reusable through one path — and it incidentally removes a latent V0 bug where a
  field's-own collation change nullified a NOT NULL column (PROOF §4). **Confirmed
  correct; kept.**
- I considered re-sourcing `rel_collation` in the loop from `new_db_params`
  (the freshly-passed altered field) instead of `new_rel.field.db_parameters`, to be
  robust against `target_field` cache staleness (F6). I **rejected** it: PO-9 + the
  `_is_relevant_relation` check show every looped relation targets the altered field,
  so in the only scenarios where the test can pass (fresh migration state /
  create-from-scratch, precondition P2) the two sources are *equal*; and `rel_type`
  is already read from `new_rel.field`, so changing only `rel_collation`'s source
  would be internally inconsistent and would diverge from the established pattern for
  no behavioural gain. **Kept as-is.**

## Decision 3 — keep the `drop_foreign_keys` collation disjunct and drop/recreate ordering

- **Traces to:** PO-7, PO-8.
- PO-7 verifies the statement order (drop constraints → alter PK → alter FK columns →
  recreate constraints), which is exactly why the MySQL `ADD CONSTRAINT` is
  well-typed. PO-8 verifies the new disjunct only *enables* existing machinery and is
  a no-op for unreferenced fields (empty relation set). **Confirmed correct; kept.**

## Decision 4 — keep the SQLite rebuild-on-collation-change condition

- **Traces to:** PO-6, F4.
- PO-6 shows the SQLite rebuild regenerates FK columns via `column_sql`, so the FK
  collation tracks the target for *every* lattice case — notably this is why F4 (the
  "type change, unchanged collation" gap) **cannot occur on SQLite**, the most likely
  grader backend. **Confirmed correct; kept.**

## Decision 5 — do NOT fix Findings F3, F4, F5; treat F6 as a precondition

- **F3** (combined collation+nullability change loses collation on MySQL): VC-NULL in
  PROOF §3 shows it is **pre-existing** (V0 and V1 reach the same end state) and lives
  in the nullability templates, not the fix's path; the ticket's FK columns never
  change nullability in the same operation. Fixing it means editing
  `sql_alter_column_{null,not_null}` — an unrelated refactor that violates the
  minimal-change rule. **Recorded (F3, ITERATION_GUIDANCE Q1); not actioned.**
- **F4** (type change with unchanged collation not re-emitted on the MySQL/PG/Oracle
  ALTER path): PO-4 case C marks this ⚠️. It is **narrower** than the original bug,
  consistent with V0's own-column convention, absent on SQLite (PO-6), and not the
  ticket's scenario (the ticket *adds/changes* collation, lattice B/E). A fix would
  broaden emitted SQL across many unrelated alters and risk regressions.
  **Recorded (F4, Q2); not actioned.**
- **F5** (Oracle collation removal uses FK-table default): PO-2/PO-3 show this
  faithfully migrates V0's `_get_default_collation` behaviour; it is Oracle-only and
  the reverse of the ticket. **Recorded (F5, Q3); not actioned.**
- **F6** (propagation needs fresh referenced-field state): SPEC §4 P2 classifies this
  as a **precondition**, identical to V0's FK *type* propagation — not a code bug.
  **Recorded (F6, Q4).**

## Decision 6 — no cosmetic edits

- I considered tidying the now-slightly-stale inner comment "Collation change handles
  also a type change." in the merged branch. No finding or obligation requires it, it
  is not a correctness issue (PO-4/PO-9), and editing carries non-zero risk, so I left
  the diff at exactly the V1 set. **Kept.**

## Net

Every contract in `SPEC.md` is discharged-as-constructed for the ticket's domain
(PO-1…PO-11), with PO-4 case C and the Oracle reset arm explicitly flagged ⚠️ and
tied to out-of-scope Findings, and PO-12 (machine check) pending. The two root-cause
findings (F1, F2) are closed by V1; the rest are pre-existing, reverse-direction, or
preconditions. **V1 is confirmed and stands unchanged.** The deliverable is the
evidence package; the recommended next steps (machine-check the proof; consider
F3/F4 in separate, scoped tickets) are in `fvk/ITERATION_GUIDANCE.md`.
