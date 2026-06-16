# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Remove the reported FieldError for non-natural-key m2m references

For every related queryset state `qs(SEL, LOAD, ROWS)`, non-natural-key m2m
serialization must reach `ok(projectPks(ROWS))`, not `fieldError()`, even when
`SEL` records relation traversal inherited from a custom default manager.

Evidence: E1, E2, E4.

Formal claim: `C1` in `fvk/serializer-m2m-spec.k`.

Status: discharged by V1 in the constructed proof.

## PO-2: Preserve primary-key-only output

Clearing `select_related` must not change the serialized m2m values. The output
for the non-natural-key branch remains the related primary key list.

Evidence: E4, E5.

Formal claim: `projectPks(ROWS)` is unchanged by `clearSelectRelated()` and
`onlyPk()`.

Status: discharged by the frame rules in `fvk/mini-serializer-queryset.k`.

## PO-3: Use the actual clearing API

The clearing operation must be `select_related(None)`, not no-argument
`select_related()`, because the local QuerySet implementation documents and
implements only the `None` form as clearing.

Evidence: E3, E6.

Formal claim: `clearSelectRelated(qs(_, LOAD, ROWS)) => qs(noSelectRelated(), LOAD, ROWS)`.

Status: discharged by inspection of `repo/django/db/models/query.py`.

## PO-4: Cover both serializer implementations

The fix must cover Python-derived serializers and XML because both have a
separate non-natural-key m2m primary-key query path.

Evidence: E4, E5.

Formal claim: C1 applies to the Python-derived branch; C4 in `fvk/SPEC.md`
maps the same claim to XML's duplicated branch.

Status: discharged by V1 edits in both files.

## PO-5: Preserve natural-key and explicit-through behavior

The fix must not clear useful manager-level `select_related` state on the
natural-key path, and must not change the existing skip behavior for m2m fields
with explicit through models.

Evidence: E4, E5 and the existing branch guards.

Formal claim: frame condition in `fvk/SPEC.md`, C5.

Status: discharged by source inspection: V1 changes only the `else` branch where
primary keys are serialized.

## PO-6: Maintain public compatibility

No public serializer API, output shape, or model-manager contract may change.

Evidence: public compatibility audit in `fvk/SPEC.md`.

Formal claim: frame condition over method signatures and output constructors.

Status: discharged by source inspection: V1 changes only internal queryset
composition.

## PO-7: Honesty gate

The proof artifacts must not be represented as machine-checked, and tests must
not be removed based on this constructed proof alone.

Evidence: FVK verify instructions.

Status: discharged by labeling all artifacts "constructed, not
machine-checked" and by not editing tests.
