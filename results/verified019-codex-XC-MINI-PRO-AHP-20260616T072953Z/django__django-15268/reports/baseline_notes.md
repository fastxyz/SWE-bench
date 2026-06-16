# Baseline Notes

## Root Cause

`AlterUniqueTogether` and `AlterIndexTogether` inherit `ModelOptionOperation.reduce()`, which only collapses operations of the same concrete class on the same model. When the autodetector emits split operations such as clearing both together options before re-adding their final values, each operation treats the other together option on the same model as a blocking model reference. This prevents the optimizer from reducing the earlier clear operation with the later final operation.

The two together options mutate independent model options, so an `AlterUniqueTogether` operation can be optimized across an `AlterIndexTogether` operation for the same model, and vice versa. The existing behavior for same-option reductions should remain unchanged so later `AlterUniqueTogether` or `AlterIndexTogether` operations replace earlier ones.

## Changed Files

`repo/django/db/migrations/operations/models.py`

Added `AlterTogetherOptionOperation.reduce()`. It returns `True` when the operation being compared is the other together-option operation on the same model, allowing the migration optimizer to pass through it and then collapse repeated operations of the same option. Same-option operations and `DeleteModel` continue to use the existing parent reduction behavior.

## Assumptions and Alternatives

I assumed the fix belongs in the operation reduction logic rather than the autodetector because the issue describes an optimization failure for operation sequences, and `MigrationOptimizer` already delegates these decisions to `Operation.reduce()`.

I considered changing `ModelOptionOperation.reduce()` to allow all different model option operations on the same model to pass through each other, but rejected that as too broad. Options such as table name, managers, ordering, and Python-visible model options may have different ordering or state implications. The change is limited to `AlterUniqueTogether` and `AlterIndexTogether`, which are the two split `AlterFooTogether` operations described in the issue.

I also assumed test files must remain untouched per the task instructions, so I did not add or update visible tests.
