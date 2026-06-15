# Baseline Notes

## Root cause

`Collector.delete()` has an optimized branch for deleting a single object with no dependencies. That branch calls `DeleteQuery.delete_batch()` and returns immediately. The normal deletion path later clears the primary key on collected model instances, but the optimized branch returned before reaching that shared cleanup, leaving the deleted instance's in-memory primary key set.

## Files changed

- `repo/django/db/models/deletion.py`: after the optimized single-object fast delete succeeds, clear the instance primary key with the model's primary-key attname before returning. This mirrors the cleanup already done by the normal collected-instance path without changing queryset fast deletes or cascade handling.

## Assumptions and alternatives considered

- I assumed the issue concerns `Model.delete()` on a saved instance that is eligible for the optimized single-object fast delete path: one collected model, one collected instance, no cascades, parents, private bulk relations, or delete/m2m signal listeners.
- I did not move the existing post-delete cleanup into a helper because the described regression is isolated to the early return in the optimized branch, and extracting shared code would be a broader refactor for the same behavior.
- I did not add field-update cleanup to the optimized branch. A model eligible for `can_fast_delete(instance)` should not have collected `field_updates`; models requiring `on_delete` field updates are handled by the normal path.
- I did not modify tests because the task requires the fixed suite to remain hidden and source-only.
