# FVK Notes

## Decision

V1 stands unchanged. The FVK pass did not justify further edits to
`repo/django/forms/models.py`.

## Trace to findings and proof obligations

F-001 identifies the original bug: inline form construction cleared a defaulted
non-primary UUID `to_field` on the unsaved parent. PO-001 requires preserving
that parent value, and PO-006 requires that `_construct_form()` can still read
the preserved alternate key for child FK assignment. V1 satisfies both by
limiting the `setattr(..., None)` mutation to `to_field.primary_key` and leaving
non-PK values on the parent.

F-002 records why a simpler fix was rejected. Merely skipping the mutation for
all `to_field` cases would preserve the parent UUID but could expose the
generated unsaved UUID as the inline hidden initial value. PO-002 requires an
empty initial for defaulted non-PK `to_field` values, while PO-004 requires
`InlineForeignKeyField` to honor an explicit `initial`. V1 satisfies this by
passing `initial=None` in the alternate-key case and by preventing
`InlineForeignKeyField.__init__()` from overwriting explicit `initial`.

F-002 and PO-003 also require preserving the historical defaulted primary-key
behavior covered by the existing UUID formset tests. V1 keeps the primary-key
mutation branch unchanged, so no additional edit was needed.

F-003 and PO-007 cover compatibility. No signature changed, and callers that do
not provide `initial` still get the old parent-derived initial behavior. This is
why the audit did not add a new public API or callsite change.

F-004 and PO-008 record the verification limitation: the K proof is constructed
but not machine-checked, and no tests or code were run because the task forbids
execution. This does not affect the source decision, but it does mean no test
removal is recommended.

## Artifacts

The required FVK files are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal core is also present:

- `fvk/mini-inline-formset.k`
- `fvk/inline-formset-spec.k`

All formal claims are labeled constructed, not machine-checked.
