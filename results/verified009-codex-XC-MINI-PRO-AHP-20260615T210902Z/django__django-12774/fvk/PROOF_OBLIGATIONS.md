# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent Adequacy

The formal accept/reject predicate must match the public issue intent:
single-field total `UniqueConstraint`s qualify as unique fields for
`in_bulk()`, while non-unique fields still raise the existing `ValueError`.

Evidence: SPEC ledger E1, E2, E4, E5.

Discharge: pass, by the intent-first contract in `fvk/SPEC.md` and the
round-trip audit in `fvk/SPEC_AUDIT.md`.

## PO2: Single-Key Soundness

`in_bulk()` may accept only key forms that identify one object per dictionary
key: `pk`, `unique=True`, or a total single-field `UniqueConstraint`.

Evidence: SPEC ledger E3, E5, E6.

Discharge: pass. The V2 code filters constraints by `len(constraint.fields) ==
1` and by membership in `opts.total_unique_constraints`.

## PO3: Field Identifier Normalization

When Django resolves `field_name` to a field, a one-field total constraint that
uses either the resolved field's `name` or `attname` must be treated as proving
that same field unique.

Evidence: SPEC ledger E7; finding F2.

Discharge: pass after V2. The code builds
`field_names = {field.name, getattr(field, 'attname', field.name)}` and checks
intersection with the single-field constraint identifiers.

## PO4: Backward Compatibility of Accepted Fields

Fields accepted before V1, especially `pk` and `unique=True` fields, must remain
accepted.

Evidence: pre-existing `in_bulk()` behavior and public lookup tests identified
by source inspection.

Discharge: pass. `field_name == 'pk'` still bypasses validation, and
`field.unique` still accepts unique fields before constraint matching matters.

## PO5: Reported Bug Reproduction Path

For `Article.slug` with `UniqueConstraint(fields=["slug"], condition=None)`,
the validation path must not raise the non-unique-field `ValueError`.

Evidence: SPEC ledger E1, E2; finding F1.

Discharge: pass. The resolved field has `field.name == "slug"` and the
single-field constraint contributes `"slug"` to `unique_fields`, so the reject
guard is false.

## PO6: Rejection of Non-Qualifying Constraints

Conditional and composite unique constraints must not satisfy the single-field
validation requirement.

Evidence: SPEC ledger E3, E6; findings F3, F4.

Discharge: pass. Conditional constraints are absent from
`opts.total_unique_constraints`; composite constraints fail the
`len(constraint.fields) == 1` filter.

## PO7: Honesty Gate

The FVK proof artifacts must remain labeled "constructed, not
machine-checked"; tests and K tooling must not be executed in this session.

Evidence: user task constraints and FVK verify.md honesty gate.

Discharge: pass. Commands are recorded in artifacts but not executed.
