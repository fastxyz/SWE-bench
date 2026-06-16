# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Decision

Keep V1 source code unchanged.

The FVK audit confirms that V1 discharges the required `old_fields` reverse
behavior:

- F1 plus PO1 show that backwards now restores the generated old index name.
- F1 plus PO2 show that a forwards/backwards/forwards sequence no longer leaves
  the second forwards in the rename-to-self state.
- PO3 and PO4 show that the implementation preserves migration routing and
  backend abstraction.

## No additional source edits

No further production-code edit is justified by the audit.

The only tempting alternative was to broaden the branch to unique constraints
and use a `"_uniq"` suffix. F3, PO5, and PO6 reject that as outside the
operation's current public semantics: `state_forwards()` removes
`index_together`, not `unique_together`, and the forward database lookup asks
for indexes.

## Suggested future tests

The fixed test suite is hidden and must not be edited here. If writing public
tests later, add coverage for:

- `RenameIndex(old_fields=...)` forwards/backwards/forwards on an
  `index_together` model.
- The expected generated name after backwards, computed with
  `schema_editor._create_index_name(..., suffix="_idx")`.
- A backend with native rename support and a backend using drop/recreate,
  because V1 delegates through `schema_editor.rename_index()`.

## Residual risk

- The proof is constructed, not machine-checked.
- Full Django runtime behavior is abstracted to the database index-name
  transition.
- The issue prose's `unique_together` wording remains ambiguous, but the audited
  operation does not provide unique-constraint state semantics.
