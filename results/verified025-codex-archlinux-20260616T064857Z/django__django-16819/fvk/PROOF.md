# FVK Proof

Status: constructed, not machine-checked. This proof was reasoned from the source
and formal artifacts only; no commands were run.

## Machine-Check Commands Not Run

These are the commands to run in an environment with K installed:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/migration-optimizer-spec.k
kprove fvk/migration-optimizer-spec.k
```

Expected machine-check outcome after the V2 patch: `kprove` discharges the claims
to `#Top`.

## Claim C1: Direct AddIndex/RemoveIndex Cancellation

Formal claim:

```k
reduce(addIndex(M, N, P), removeIndex(M, N)) => replace(.OpList)
```

Proof sketch:

1. Symbolically execute `AddIndex.reduce(operation, app_label)` with
   `operation = RemoveIndex(M, N)`.
2. `isinstance(operation, RemoveIndex)` is true.
3. `self.model_name_lower == operation.model_name_lower` is true because both
   model names are canonical `M`.
4. `self.index.name == operation.name` is true because both names are exact `N`.
5. The branch returns `[]`, represented by `replace(.OpList)`.

Discharges: PO-1, PO-2.

## Claim C2: AddIndex/RenameIndex Composition

Formal claim:

```k
reduce(addIndex(M, Old, P), renameIndex(M, New, someName(Old)))
  => replace(addIndex(M, New, P), .OpList)
```

Proof sketch:

1. Symbolically execute `AddIndex.reduce(operation, app_label)` with
   `operation = RenameIndex(M, new_name=New, old_name=Old)`.
2. The `RemoveIndex` branch is skipped.
3. `isinstance(operation, RenameIndex)` is true.
4. The same-model guard is true for canonical `M`.
5. `operation.old_name` is present.
6. `self.index.name == operation.old_name` is true because both are `Old`.
7. `self.index.clone()` preserves all index payload attributes.
8. Assigning `index.name = operation.new_name` changes only the name to `New`.
9. The method returns `[self.__class__(self.model_name, index)]`, represented in
   the base-operation mini semantics by `replace(addIndex(M, New, P), .OpList)`.
   For public subclasses with the same constructor shape, the concrete class is
   preserved.

Discharges: PO-4, PO-5, PO-7, PO-11. This is the V2 improvement over V1.

## Claim C3: Unrelated-Model Pass-Through

Formal claim:

```k
reduce(addIndex(M, N, P), otherOp(false)) => cross(true)
```

Proof sketch:

1. No `AddIndex.reduce()` specific branch matches `otherOp(false)`.
2. Control falls through to `IndexOperation.reduce()`.
3. `Operation.reduce()` is false for ordinary non-elidable operations.
4. `otherOp(false).references_model(M)` is false in the mini semantics.
5. `not operation.references_model(self.model_name, app_label)` is true.
6. The method returns boolean `True`, represented by `cross(true)`.

Discharges: PO-3.

## Claim C4: Non-Matching Names Do Not Cancel

Formal claim:

```k
N1 =/=String N2
requires reduce(addIndex(M, N1, P), removeIndex(M, N2)) => cross(false)
```

Proof sketch:

1. Symbolically execute `AddIndex.reduce()` with same-model remove but different
   exact names.
2. The `RemoveIndex` branch guard fails because `self.index.name ==
   operation.name` is false.
3. The `RenameIndex` branch does not apply.
4. `IndexOperation.reduce()` checks whether the later operation references the
   model. `RemoveIndex(M, N2)` does reference `M`.
5. The pass-through expression is false, so no replacement or crossing is
   allowed.

Discharges: PO-2, PO-8.

## Optimizer-Level Composition

For the sequence from FVK-F1:

```python
AddIndex("Pony", old_idx)
RenameIndex("Pony", new_name="new_idx", old_name="old_idx")
RemoveIndex("Pony", "new_idx")
```

One optimizer iteration applies C2 and produces:

```python
AddIndex("Pony", new_idx)
RemoveIndex("Pony", "new_idx")
```

The next iteration applies C1 and produces:

```python
[]
```

This uses the documented optimizer loop that repeats until the operation list no
longer changes.

## Residual Risk

- Termination and performance of the full optimizer loop are not proved.
- Same-model unrelated index/field commutation is not proved or implemented.
- The formal semantics abstracts Python dispatch and Django model state to the
  reducer algebra relevant to this issue.
- The proof is constructed, not machine-checked.

## Test Recommendation

No tests were edited. Any future test-removal recommendation is conditioned on
machine-checking the K claims. Until then, keep all tests.
