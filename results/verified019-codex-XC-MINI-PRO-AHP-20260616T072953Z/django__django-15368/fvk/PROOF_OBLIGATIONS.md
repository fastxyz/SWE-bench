# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent Adequacy for Plain `F()`

Statement: a plain `F(NAME)` value assigned to an instance field and passed through `bulk_update()` is in the verified domain and must resolve to `Column(NAME)`.

Evidence: E1, E2, E3.

K claim: `bulkThen(Resolvable(FRef(NAME))) => Column(NAME)`.

Status: discharged by construction in `bulk-update-spec.k`.

## PO-2: Correct Branch Predicate

Statement: `bulk_update()` must classify values by the presence of `resolve_expression`, not by membership in the `Expression` class hierarchy.

Evidence: E4, E5, E6.

Source check: `repo/django/db/models/query.py` uses `if not hasattr(attr, 'resolve_expression')`.

Status: discharged by V1.

## PO-3: Expression Preservation

Statement: when a field value has `resolve_expression`, it must not be wrapped in `Value()` by `bulk_update()` before `When(..., then=attr)` is constructed.

Evidence: E3, E4, E5.

K claims: `Resolvable(FRef(NAME)) => Column(NAME)` and `Resolvable(ExprNode(SQL)) => ExprNode(SQL)`.

Status: discharged by V1 and source inspection of `When.resolve_expression()` / `Case.resolve_expression()`.

## PO-4: Literal Value Preservation

Statement: when a field value lacks `resolve_expression`, it remains a literal assignment and is wrapped in `Value(attr, output_field=field)`.

Evidence: E7 and pre-existing `bulk_update()` behavior.

K claim: `Plain(V) => Param(V)`.

Status: discharged by V1; the literal branch is unchanged except for the predicate's protocol alignment.

## PO-5: Source Loop and Frame Conditions

Statement: the nested batch, field, and object loops continue to build updates for every requested object/field pair, preserving PK conditions, object order within each batch, field association, optional casts, transaction handling, and row-count accumulation.

Evidence: E7.

Loop invariant summary:

- Completed batches satisfy PO-2 through PO-4 pointwise.
- Completed fields in the current batch satisfy PO-2 through PO-4 pointwise.
- Completed objects in the current field have one `When(pk=obj.pk, then=normalized_attr)` each.

Status: discharged by source diff inspection; V1 modifies only the normalization predicate inside the innermost loop.

## PO-6: Public Compatibility

Statement: the fix must not require caller changes or break subclass/override dispatch.

Evidence: E7, E8 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged. The public method signature and return behavior are unchanged.

## PO-7: Honesty Gate

Statement: proof and test-redundancy conclusions must be labeled constructed, not machine-checked; tests must not be removed or modified in this task.

Evidence: FVK `verify.md` honesty gate and user constraints.

Status: discharged. No tests or code were run; no test files were modified.
