# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No additional production-code edit is justified. V1's `UUIDField.get_prep_value()` override discharges the issue-specific proof obligations:

- PO-001: valid textual UUID values are normalized through `to_python()`.
- PO-002: GFK source keys match related-object UUID primary key keys.
- PO-003: existing prefetch assignment then populates the relation.
- PO-005: DB preparation remains compatible.
- PO-006 and PO-007: public API and non-UUID behavior are preserved.

## Do Not Change

Do not alter `GenericForeignKey.get_prefetch_queryset()` in this iteration. F-003 and PO-007 show that the generic path was already delegating normalization to the target primary key field; UUIDField was the missing typed-field implementation.

Do not add direct `GenericForeignKey` filter/exclude support. F-002 and PO-006 show that this is explicitly outside the documented prefetch behavior.

Do not modify tests in this workspace. The task forbids test edits.

## Future Work

After this benchmark task, a normal Django development pass should add visible regression coverage for F-005:

- model with `UUIDField(primary_key=True)`;
- model with `CharField` object id and `GenericForeignKey`;
- assertion that `prefetch_related()` returns the UUID target object and does not leave the relation cached as `None`.

Machine-checking can be attempted later with the commands recorded in `fvk/PROOF.md`. Until then, no test-removal recommendation should be acted on.
