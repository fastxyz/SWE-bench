# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional source change justified by the public issue, source control flow, or proof obligations.

## Trace From Findings and Proof Obligations

- `F1` traces to `PO1` and `PO2`: the reported bug is the optimized single-object fast-delete branch returning before the same primary-key cleanup performed by the normal collected path. V1's `setattr(instance, model._meta.pk.attname, None)` after `delete_batch()` discharges this obligation.
- `F2` traces to `PO3`: duplicating field-update cleanup in the optimized branch is not required. `can_fast_delete()` excludes the dependency cases that would populate `field_updates`, so broadening the branch would add unnecessary behavior.
- `F3` traces to `PO4`, `PO5`, and `PO6`: V1 preserves exception ordering, public signatures, return shape, queryset delete behavior, cascade behavior, and signal behavior because the change is a single post-`delete_batch()` side effect in the optimized instance-delete branch.
- `F4` applies to all proof obligations: the proof is constructed but not machine-checked because the task forbids running K tooling, tests, Python, or Django code. This does not require a source change, but it does mean tests should be kept until a normal execution environment is available.

## Alternatives Considered

- Refactoring shared cleanup into a helper was rejected because `F1/PO1` only requires the optimized branch to perform the same PK cleanup before returning. A helper would be broader churn without a stronger obligation.
- Adding field-update cleanup to the optimized branch was rejected under `F2/PO3`; the branch's own fast-delete predicate rules out those cases.
- Changing queryset deletion was rejected under `F3/PO6`; the issue concerns an in-memory model instance after `instance.delete()`, not rows deleted through queryset raw deletion.
