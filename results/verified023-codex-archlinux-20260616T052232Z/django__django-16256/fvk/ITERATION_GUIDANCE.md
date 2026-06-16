# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The audit found the original issue mechanism and confirmed that V1 addresses it
with local async wrappers on all manager factories that have relation-specific
sync `create()`, `get_or_create()`, and `update_or_create()` methods.

## Recommended tests for a normal development workflow

Do not modify tests in this benchmark. For a normal Django patch, add public
tests covering:

1. Reverse many-to-one `acreate()`, `aget_or_create()`, and
   `aupdate_or_create()` create/update objects through the bound parent.
2. Many-to-many `acreate()`, `aget_or_create()`, and `aupdate_or_create()` add
   created objects to the relation.
3. Many-to-many async create/get/update-or-create preserve `through_defaults`
   for custom through models.
4. Generic relation `acreate()`, `aget_or_create()`, and
   `aupdate_or_create()` populate content type and object id fields.
5. Normal manager/queryset async methods still behave as before.

## Next proof iteration

If K tooling becomes available, run the commands recorded in `fvk/PROOF.md`.
If a full Python semantics is available, replace `mini-related-manager.k` with a
literal Python method-resolution model and re-prove PO1-PO6 against the edited
source.

## Open questions

None for this issue. The generic relation extension was considered and kept
because it has the same root cause and public sync related-manager evidence.

