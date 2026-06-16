# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V2 should not leave V1 unchanged. FVK-F1 identified a directly related missing
case: `AddIndex` followed by `RenameIndex` of the same just-added index did not
compose, so a later `RemoveIndex` of the final name could not cancel the add.

Applied change:

- Extend `AddIndex.reduce()` with a `RenameIndex` branch.
- Clone the existing index, assign `operation.new_name`, and return a single
  operation of `self.__class__` with the renamed clone, preserving public
  subclasses such as `AddIndexConcurrently`.

Retained V1 behavior:

- Exact index-name matching for `RemoveIndex` cancellation.
- Model-reference pass-through on `IndexOperation`.
- Conservative blocking for same-model operations without a dependency-specific
  index analysis.

## Suggested Public Tests For A Future Test Patch

Do not modify tests in this benchmark run. If tests were allowed, add focused
optimizer tests for:

- `AddIndex("Pony", idx)` followed by `RemoveIndex("Pony", idx.name)` reduces to
  `[]`.
- `AddIndex("Pony", old_idx)`, `RenameIndex("Pony", old_name=old_idx.name,
  new_name="new_idx")`, `RemoveIndex("Pony", "new_idx")` reduces to `[]`.
- Different exact index names do not reduce.
- An unrelated-model operation between matching add/remove does not block
  reduction.

## Questions For A Broader Follow-Up

- Should index operations analyze field/expression dependencies enough to pass
  through same-model operations that provably touch unrelated fields or indexes?
- Should third-party `AddIndex` subclasses with non-standard constructors opt
  out of inherited rename composition, or should Django document the constructor
  compatibility expectation for subclasses that inherit this reducer?

The remaining question is outside the public issue's required fix and is not
needed to discharge the current obligations for Django's public subclasses.
