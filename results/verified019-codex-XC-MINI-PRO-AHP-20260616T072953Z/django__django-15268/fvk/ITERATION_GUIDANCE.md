# FVK Iteration Guidance

Status: constructed from public evidence, not machine-checked.

## Decision

V1 was close but not final. F-001 showed that the override should preserve inherited reducer results before applying the new cross-option transparency rule. V2 makes that refinement and should stand unless later machine checking or tests reveal an unmodeled integration issue.

## Source Changes to Keep

Keep the `AlterTogetherOptionOperation.reduce()` override in `repo/django/db/migrations/operations/models.py` with this shape:

```python
result = super().reduce(operation, app_label)
if result is not False:
    return result
if other together option on same model:
    return True
return False
```

This is justified by:

- F-001 / PO-1: preserve inherited non-`False` behavior.
- F-002 / PO-2 / PO-4: enable the issue's split remove/add sequence to collapse.
- F-003 / PO-5: keep field operations as boundaries.

## Changes Rejected

- Do not broaden this to all `ModelOptionOperation` subclasses. INT-2 names only `AlterUniqueTogether` and `AlterIndexTogether`, and PO-7 keeps the fix scoped to those operations.
- Do not change the autodetector. The problem is an optimizer reduction failure, and PO-4 is discharged by operation-level reduction behavior.
- Do not alter tests in this task. The user explicitly fixed the test suite and forbade test-file changes.

## Follow-Up Tests for a Normal Development Environment

These are recommendations only; they were not run or added here.

- Direct optimizer test: `[AlterUniqueTogether(set()), AlterIndexTogether(set()), AlterUniqueTogether({("col",)}), AlterIndexTogether({("col",)})]` optimizes to the final two operations.
- Reverse transparency test: an earlier `AlterIndexTogether` can reduce across an intervening `AlterUniqueTogether` to a later `AlterIndexTogether`.
- Boundary test: a field operation between clearing and re-adding a together option blocks reduction when the later option references that field.
- Inherited behavior test: same-option operations still collapse to the later operation, `DeleteModel` behavior is unchanged, and elidable inherited behavior is not bypassed.

## Machine-Checking Guidance

The proof is constructed only. In an environment where K tooling is available, complete the abstract mini semantics and run:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/alter-together-reduce-spec.k
kprove fvk/alter-together-reduce-spec.k
```

Until those return `#Top`, do not remove tests based on this proof.
