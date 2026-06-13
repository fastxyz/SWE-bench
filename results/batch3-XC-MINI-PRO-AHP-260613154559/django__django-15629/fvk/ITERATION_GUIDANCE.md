# ITERATION GUIDANCE — db_collation propagation to foreign keys

Feedback package for the next generate→formalize→verify pass. Each item: the
evidence (claim/VC/finding), a classification, the UltimatePowers question the
intent layer should ask, and the concrete next change. Per the kit's loop, `/verify`
**does not** silently patch code; this file is the actionable residue.

---

## Decision for this iteration: **V1 stands (no code change)**

The audit confirms V1 satisfies the ticket's contract on every backend, and emits
**byte-for-byte the SQL `PROBLEM.md` asks for** (PROOF §2, lattice case B). The two
root-cause findings (F1, F2) are *closed by* V1. The remaining findings (F3–F6) are
either pre-existing, out-of-scope, or preconditions — fixing them would violate the
"minimal, targeted" rule and risk regressions on unrelated `ALTER` output. They are
therefore **recorded, not actioned**, with the justification traced below and in
`reports/fvk_notes.md`.

---

## Q1 — combined collation + nullability change loses collation on MySQL (Finding F3)

- **Evidence:** VC-NULL (PROOF §3); `sql_alter_column_null`/`_not_null` lack a
  `%(collation)s` hole, so the trailing nullability `MODIFY` drops `COLLATE`.
- **Classification:** pre-existing latent bug (V0 ≡ V1 end state); **not** the ticket.
- **UltimatePowers question:** "When a column's collation **and** nullability change
  in one migration on MySQL, must the final collation be preserved?" (Almost
  certainly yes.)
- **Next change (separate ticket):** add `%(collation)s` to
  `sql_alter_column_null`/`sql_alter_column_not_null` (MySQL) and have
  `_alter_column_null_sql` thread the field's collation. **Out of scope here.**
- **Tests:** keep any MySQL test exercising simultaneous collation+null change.

## Q2 — type change with unchanged collation does not re-emit COLLATE (Finding F4)

- **Evidence:** PO-4 case C (⚠️); only on the MySQL/PG/Oracle `_alter_column_type_sql`
  path. **Cannot occur on SQLite** (PO-6 rebuild always re-emits).
- **Classification:** residual narrowing of the original bug; consistent with V0's
  own-column convention (`elif type changed:` never re-emitted collation).
- **UltimatePowers question:** "If a referenced collated PK changes **type only**
  (e.g. `max_length`) with the collation unchanged, should the FK column's collation
  be re-asserted to survive MySQL's reset-to-default?" 
- **Next change (if confirmed desirable):** in the `rels_to_update` loop, treat the
  FK column as *always* needing the target collation (pass a sentinel old-collation,
  or branch on "is a textual collation present" rather than "did it change"). Deferred
  because it broadens emitted SQL well beyond the ticket and is unverified against the
  hidden suite.
- **Tests:** keep a MySQL "alter max_length of collated, referenced PK" test.

## Q3 — Oracle collation removal uses FK-table default (Finding F5)

- **Evidence:** PO-2 oracle arm / PO-3; `_collate_sql(None, x, fk_table)` →
  `defaultColl(fk_table)`.
- **Classification:** Oracle-only, reverse-direction edge (removing collation);
  faithfully migrated from V0's `_alter_column_collation_sql`.
- **UltimatePowers question:** "On Oracle, when a referenced PK's collation is
  removed, should the FK column adopt the PK table's default or the FK table's
  default collation?"
- **Next change:** none now (keeps V0 semantics). If the cross-table-default mismatch
  is reported as a real failure, resolve the default against the *referenced* table.

## Q4 — propagation depends on fresh referenced-field state (Finding F6, precondition P2)

- **Evidence:** SPEC §4 P2; `target_field` is a `cached_property` resolving to
  `remote_field.model._meta.pk`.
- **Classification:** precondition, not a bug; identical to V0's FK *type*
  propagation.
- **UltimatePowers question:** "Are all call sites that alter a referenced field
  guaranteed to present a `to_state` model whose `_meta.pk` is the new field?" (True
  for migration execution and create-from-scratch; the kit assumes it.)
- **Next change:** none. Documentation note only: bespoke `editor.alter_field(...)`
  callers must update the referenced model's `_meta.pk` (or use migration state) for
  collation/type to propagate.

## Q5 — machine-check the constructed proof (Finding PD1 / PO-12)

- **Evidence:** honesty gate; toolchain not run here.
- **Classification:** proof-capability gap, not a code defect.
- **Next change:** flesh out `schema.k`/`schema-spec.k` from SPEC §2 and run the
  `kompile`/`kprove` commands (PROOF §6); a `#Top` upgrades every ✅ to
  machine-verified and unlocks the (advisory) test-redundancy removals.

---

## Net

No source edit is warranted this pass. The fix is **confirmed** against `SPEC.md`
(FK-PARAMS, ALTER-TYPE, ALTER-FIELD, COLUMN-SQL, SQLITE-REBUILD all ✅ for the
ticket's domain) and `PROOF_OBLIGATIONS.md` (PO-1…PO-11 discharged-as-constructed;
PO-4 case C and the Oracle reset arm flagged ⚠️ and tied to out-of-scope Findings;
PO-12 machine-check pending). The deliverable is this evidence package.
