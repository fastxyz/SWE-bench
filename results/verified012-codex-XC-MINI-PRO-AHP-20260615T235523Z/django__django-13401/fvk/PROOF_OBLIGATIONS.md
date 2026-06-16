# Proof Obligations

Status: constructed, not machine-checked.

## PO-EQ-OWNER

For all fields `f` and `g`, if both are `Field` instances:

`f == g` iff `f.creation_counter == g.creation_counter` and
`owner(f) == owner(g)`, where `owner(x)` is `getattr(x, 'model', None)`.

Issue trace: E1, E2, E4. Finding trace: FVK-F1.

## PO-HASH-CONSISTENCY

For all fields `f` and `g`, if `f == g`, then `hash(f) == hash(g)`.

V1 proof target: equality and hashing both use
`(creation_counter, getattr(field, 'model', None))`.

Issue trace: E5. Finding trace: FVK-F2.

## PO-SET-CARDINALITY

For fields copied from abstract base `A` onto concrete models `B` and `C`, if
they share the same copied `creation_counter` and have different `model`
owners, then inserting both into a Python set retains both elements.

Reason: either their hashes differ, or in any collision path equality is false.

Issue trace: E3, E4. Finding trace: FVK-F1.

## PO-LT-PRIMARY-COUNTER

For all fields `f` and `g` with different creation counters:

`f < g` iff `f.creation_counter < g.creation_counter`.

The model owner must not affect this branch.

Issue trace: E6, E8. Finding trace: FVK-F3.

## PO-LT-COLLISION

For all fields `f` and `g` with equal creation counters, `__lt__()` must use an
owner-sensitive tie-breaker so that same-counter fields from different models
have an ordering relation independent of declaration order.

V1 proof target: compare `_model_sort_key(model)`, where unattached fields use
`()`, and attached fields use `(model._meta.label_lower, id(model))`.

Issue trace: E5. Finding trace: FVK-F4.

## PO-ABSTRACT-CLONE

Abstract inheritance preserves a field's `creation_counter` via
`copy.deepcopy(field)`, then assigns the copied field's owner through
`contribute_to_class()` before `_meta.add_field()` performs ordered insertion.

This obligation connects the issue reproduction to the comparison methods.

Issue trace: E7, E8. Finding trace: FVK-F1, FVK-F3.

## PO-COMPATIBILITY

The fix must not change the public comparison method signatures or the
non-`Field` `NotImplemented` behavior.

Issue trace: I6 and public compatibility audit. Finding trace: no unresolved
finding.
