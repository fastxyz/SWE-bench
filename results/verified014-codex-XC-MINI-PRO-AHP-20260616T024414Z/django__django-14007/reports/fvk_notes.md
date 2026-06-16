# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional source edit justified by
the public issue intent.

## Trace to Findings and Proof Obligations

F-001 identifies the original defect: insert-returned values skipped the normal
converter pipeline. PO-001 requires backend converters followed by field
converters for each returned column, and PO-003/PO-004 connect that compiler
result to `create()` and `bulk_create()` assignment. V1 satisfies these by
collecting backend-returned rows in `SQLInsertCompiler.execute_sql()`, computing
converters with `get_converters()`, applying them with `apply_converters()`, and
returning the converted rows to the existing assignment code.

F-002 records the expression-shape issue found during audit. PO-002 requires
converter-compatible `Col` expressions rather than raw fields because backend
converters inspect `output_field` and, on Oracle, `field`. V1 already uses
`field.get_col(self.query.get_meta().db_table)`, so no change was needed.

F-003 covers the no-`RETURNING` fallback. PO-005 requires conversion to be scoped
to `[pk]` because `last_insert_id()` returns only a primary-key value. V1 already
uses `fields = [self.query.get_meta().pk]` in that branch, preserving the prior
fallback behavior while allowing a primary-key `from_db_value()` hook to run.

F-004 covers result shape compatibility. PO-006 requires a materialized list
because `bulk_create()` may inspect `len(returned_columns)`, and it requires row
shape to remain suitable for positional zipping. V1 returns `list(rows)` and
maps converted rows back to tuples, so no additional compatibility edit was
needed.

F-005 and PO-008 summarize the compatibility audit: no public method signature,
caller protocol, or test file was changed. The only behavior changed is the
intended value conversion before assignment.

## Artifacts

The audit artifacts are in `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

I also included compact K sketches, `mini-django-insert.k` and
`django-insert-returning-spec.k`, because the FVK documentation treats formal
claims as part of the evidence package. They were not run.

## Verification Status

No tests, Python code, or K tooling were run, per task constraints. The proof is
constructed, not machine-checked.
