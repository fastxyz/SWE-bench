# Intent Specification

Status: constructed, not machine-checked.

## Intent-Only Obligations

I1. For a saved model instance deleted through `Model.delete()`, a successful delete must leave the in-memory primary-key attribute set to `None`.

Evidence: `benchmark/PROBLEM.md` says, "Deleting any model with no dependencies not updates the PK on the model. It should be set to None after .delete() call."

I2. The obligation includes the fast-deletable/no-dependencies case.

Evidence: `benchmark/PROBLEM.md` title: "`delete()` on instances of models without any dependencies doesn't clear PKs."

I3. The intended fix should mirror the existing collected-instance cleanup rather than changing unrelated delete semantics.

Evidence: the public hint says the simple fix "mimics what ... deletion.py#L324-L326 does for multiple objects."

I4. The delete return shape and public method signatures are frame conditions: the change must not alter `Model.delete()`, `QuerySet.delete()`, or `Collector.delete()` return contracts.

Evidence: the issue describes only in-memory primary-key cleanup, and the source call chain already returns `collector.delete()` results.

I5. Failed SQL deletion is outside the successful-delete postcondition. Primary-key cleanup should occur only after `delete_batch()` returns normally.

Evidence: the existing normal path performs in-memory cleanup after the database delete block; V1 places the new cleanup after `delete_batch()`.

I6. `QuerySet.delete()` fast deletes are outside the in-memory instance cleanup obligation unless concrete instances were collected.

Evidence: the issue says "`delete()` on instances"; queryset fast deletes use `_raw_delete()` without exposing individual model instances to mutate.
