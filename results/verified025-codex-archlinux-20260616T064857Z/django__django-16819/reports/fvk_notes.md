# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K commands were
run.

## Source changes after V1

`repo/django/db/migrations/operations/models.py`

- Kept the V1 `IndexOperation.references_model()` and `IndexOperation.reduce()`
  behavior. This is justified by FVK-F3 and PO-3: index operations need the same
  unrelated-model pass-through capability as other model-scoped operations so an
  `AddIndex` can find a later matching `RemoveIndex`.
- Kept the V1 direct `AddIndex` + `RemoveIndex` cancellation. This is justified
  by FVK-F2, PO-1, and PO-2: matching model plus exact index name has no net
  effect and should reduce to `[]`.
- Added an `AddIndex.reduce(RenameIndex)` branch. This is justified by FVK-F1,
  PO-4, and PO-7: adding an index and then renaming that same newly added index
  is equivalent to adding the index with the final name, preserving all other
  index attributes.
- Constructed the rename replacement with `self.__class__(self.model_name,
  index)` instead of `AddIndex(self.model_name, index)`. This is justified by
  FVK-F1b, PO-6, and PO-11: public subclasses such as `AddIndexConcurrently`
  should keep their operation class and database behavior when the rename is
  absorbed.

## Decisions to leave behavior unchanged

- Exact index-name comparison remains unchanged. FVK-F4, PO-2, and PO-8 trace
  this to `ProjectState.remove_index()`, which compares `obj.name` exactly.
- Same-model unrelated field/index commutation remains out of scope. FVK-F5 and
  PO-9 classify it as a conservative limitation rather than a required fix; a
  broader change would need dependency analysis for index fields, expressions,
  conditions, and includes.
- No test files were modified. FVK-F6 and PO-10 record the task's no-execution
  and fixed-test constraints.

## FVK artifacts

Created the required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also recorded the formal core used by the proof:

- `fvk/mini-migration-optimizer.k`
- `fvk/migration-optimizer-spec.k`
