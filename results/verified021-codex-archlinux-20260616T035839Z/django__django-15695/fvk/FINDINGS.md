# FINDINGS

Status: constructed, not machine-checked.

## F1: V1 fixes the legacy no-op reverse for `old_fields`

Input/state:

- Operation: `RenameIndex("Pony", new_name="new_pony_test_idx", old_fields=("weight", "pink"))`
- Current database after forwards: one index over the old fields named `new_pony_test_idx`
- Target state for backwards: unnamed `index_together` index over the same fields

Observed before V1:

- `database_backwards()` returned immediately.
- The database still contained `new_pony_test_idx`.
- Re-applying forwards could attempt to rename `new_pony_test_idx` to
  `new_pony_test_idx`, producing the reported PostgreSQL relation-exists error.

Expected:

- Backwards should restore the deterministic generated old index name.

V1 status:

- Satisfied. V1 computes the target model columns, calls
  `schema_editor._create_index_name(..., suffix="_idx")`, and delegates the
  rename to `schema_editor.rename_index()`.

Related proof obligations: PO1, PO2, PO4.

## F2: Public no-op test/comment is SUSPECT legacy evidence

Input/state:

- Existing public test text says reverse for an unnamed index is a no-op.

Observed:

- That behavior is exactly the issue's reported cause of non-idempotent
  forwards/backwards application.

Expected:

- The issue intent and public hint override the legacy no-op expectation.

V1 status:

- Satisfied by changing production code only. Test files remain untouched per
  task instructions; hidden/fixed tests should encode the corrected behavior.

Related proof obligations: PO1, PO2.

## F3: `unique_together` wording is ambiguous for this operation

Input/state:

- The problem prose mentions `unique_together`.
- `RenameIndex.old_fields` documentation and `state_forwards()` point to
  `index_together`, and `database_forwards()` searches `index=True`.

Observed:

- Broadening V1 to rename unique constraints would require changing state
  semantics as well as database lookup semantics.

Expected:

- Keep the audited fix scoped to the operation's public contract:
  unnamed `index_together` indexes.

V1 status:

- Confirmed unchanged. No `_uniq` suffix or unique-constraint handling was added.

Related proof obligations: PO5, PO6.

## F4: Proof is constructed only

Input/state:

- The task forbids running K tooling, Python, tests, or project code.

Observed:

- The proof artifacts and commands are written, but not machine-checked.

Expected:

- Label all FVK proof results as constructed, not machine-checked.

V1 status:

- Satisfied in `PROOF.md` and this report.

Related proof obligations: PO7.
