# Constructed Proof

Status: constructed, not machine-checked. No K tooling, Python, or tests were executed.

## Claims

The machine-facing claims are in `fvk/django-delete-spec.k`.

- `OPT-FAST-SINGLE-CLEAR-PK` proves PO1: on the optimized successful single-object fast-delete path, the object primary key map changes from `obj -> pk(P)` to `obj -> nonePk` and the delete result shape is preserved.
- `NORMAL-COLLECTED-CLEAR-PK` proves PO2 at the same abstraction level: the existing collected cleanup path changes `obj -> pk(P)` to `obj -> nonePk`.

## Proof Sketch

For `OPT-FAST-SINGLE-CLEAR-PK`, symbolic execution starts with the abstract command `singleFastDelete(obj, model, pk(P), C)`. The mini semantics rewrites this command into the ordered sequence:

1. `deleteBatch(model, pk(P), C)`;
2. `clearPk(obj)`;
3. `finishDelete(C, model)`.

The first step models the successful return of `DeleteQuery(model).delete_batch([instance.pk], using)`. The second step models the V1 `setattr(instance, model._meta.pk.attname, None)` line by updating the object primary-key map at `obj` to `nonePk`. The third step returns `deleteResult(C, model)`, preserving the same count/model result that the pre-existing optimized branch returned. By transitivity of the three rewrite steps and map update extensionality, the postcondition holds.

The pre-V1 program would correspond to the same sequence without `clearPk(obj)`. In that version, the map would remain `obj -> pk(P)`, so the PO1 postcondition could not be reached. This localizes F1 to the early return in the optimized branch.

For `NORMAL-COLLECTED-CLEAR-PK`, symbolic execution uses the existing cleanup abstraction `normalCollectedDelete(obj .Objs, model, C)`, which sequences `clearCollected(obj .Objs)` before `finishDelete(C, model)`. The one-object instance reduces to `clearPk(obj)` followed by return, yielding `obj -> nonePk`. This is the reference behavior the public hint identifies.

## Adequacy and Completeness Check

The formal English in `FORMAL_SPEC_ENGLISH.md` matches the intent-only obligations I1-I6. The proof covers the entire issue-relevant behavior space: successful `Model.delete()` on a fast-deletable instance with no dependencies. It does not claim full ORM deletion correctness, queryset raw deletion instance mutation, cascade semantics, signal ordering, database row-count correctness, or exception behavior.

## Exact Commands To Run Later

These commands are emitted for a real K environment. They were not run in this session.

```sh
cd fvk
kompile mini-django-delete.k --backend haskell
kast --backend haskell django-delete-spec.k
kprove django-delete-spec.k
```

Expected machine-check result in a K environment: `#Top` for the stated claims.

## Test Guidance

No tests were run or modified. Keep the hidden and public Django tests until both the K proof and the Django test suite can be executed. A focused regression test, when test edits are allowed, should create a fast-deletable model instance, call `instance.delete()`, and assert `instance.pk is None`.
