# FVK Spec: AddIndex/RemoveIndex Optimization

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Audited production code:

- `repo/django/db/migrations/operations/models.py`
  - `IndexOperation.references_model()`
  - `IndexOperation.reduce()`
  - `AddIndex.reduce()`

Audited optimizer context:

- `repo/django/db/migrations/optimizer.py`
  - `MigrationOptimizer.optimize_inner()`, specifically the contract that
    `Operation.reduce()` returns either a replacement operation list or a
    boolean pass-through result.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "Reduce Add/RemoveIndex migration operations." | `AddIndex(model, index)` followed by `RemoveIndex(model, index.name)` has no net state/database effect and should reduce to no operations. | Encoded by PO-1 and K claim 1. |
| I2 | prompt + optimizer docs | "two combinable operations might be separated by several hundred others" | The reduction must work through operations that do not reference the indexed model. | Encoded by PO-3 and K claim 3. |
| I3 | code contract | `Operation.reduce()` returns "a list of operations" or "a boolean" for crossing. | Direct replacements must be equal or shorter and pass-through must be boolean `True`, not a replacement list. | Encoded by PO-5. |
| I4 | state code | `ProjectState._remove_option()` removes indexes by `obj.name != obj_name`. | Index-name matching must be exact, not case-insensitive. | Encoded by PO-2 and K claim 4. |
| I5 | existing index optimizer behavior | `RenameIndex.reduce()` composes consecutive index renames. | A rename of an index added earlier in the same optimization window should compose into the add operation, preserving the index payload with the final name. | V1 failed; V2 encoded by PO-4 and K claim 2. |
| I6 | compatibility | Public operation class signatures are used by migrations and subclasses. | The fix must not change operation constructor signatures, deconstruction shape, or test files. | Encoded by PO-6. |

## Formal Domain

The mini semantics models only the optimizer-facing operation algebra needed for
this issue. Model names in the formal claims are already normalized to Django's
`model_name_lower` representation. Index names remain exact strings because the
state layer compares them exactly.

Out of scope for this proof:

- Running actual schema-editor database operations.
- Proving termination of `MigrationOptimizer.optimize()`.
- Same-model field-level commutation for unrelated fields inside an index. The
  current proof only needs unrelated-model pass-through and direct
  add/rename/remove composition.

## Formal Core

The formal core is recorded in:

- `fvk/mini-migration-optimizer.k`
- `fvk/migration-optimizer-spec.k`

Claims:

- C1: `reduce(addIndex(M, N, P), removeIndex(M, N)) => replace(.OpList)`.
- C2: `reduce(addIndex(M, Old, P), renameIndex(M, New, someName(Old))) => replace(addIndex(M, New, P), .OpList)`.
- C3: `reduce(addIndex(M, N, P), otherOp(false)) => cross(true)`.
- C4: `N1 =/=String N2` implies `reduce(addIndex(M, N1, P), removeIndex(M, N2)) => cross(false)`.

## Adequacy Audit

The formal claims match the public intent:

- I1 maps directly to C1.
- I2 maps directly to C3 and to `IndexOperation.references_model()`.
- I4 maps directly to C4 and justifies exact index-name matching.
- I5 maps directly to C2. This is the one obligation V1 missed and V2 repairs.

No formal claim preserves behavior solely because V1 had it. The only
conservative limitation retained is blocking same-model unrelated field/index
commutation, because no public evidence requires that broader optimization and
the base `Operation.references_model()` guidance says false negatives are safer
than false positives for optimizer boundaries.

## Compatibility Audit

No public constructor, method signature, deconstruction result, or migration
operation class name changes. `AddIndex.reduce()` now returns either:

- `[]` for matching remove,
- `[self.__class__(... renamed clone ...)]` for matching rename, preserving
  public subclasses such as `AddIndexConcurrently`,
- the existing superclass result otherwise.

The new `IndexOperation.references_model()` and `IndexOperation.reduce()` methods
only implement the optimizer protocol already used by `ModelOperation`.
