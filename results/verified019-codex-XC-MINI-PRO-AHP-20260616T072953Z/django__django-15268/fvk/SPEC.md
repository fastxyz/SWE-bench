# FVK Specification: django__django-15268

Status: constructed from public evidence, not machine-checked.

## Scope

The audited production unit is `AlterTogetherOptionOperation.reduce()` in `repo/django/db/migrations/operations/models.py`. Its client behavior is the reduction protocol used by `MigrationOptimizer.optimize_inner()` in `repo/django/db/migrations/optimizer.py`.

The formal domain is a finite migration operation list where:

- `U(m, v)` denotes `AlterUniqueTogether(name=m, unique_together=v)`.
- `I(m, v)` denotes `AlterIndexTogether(name=m, index_together=v)`.
- `F(m, f)` denotes a field operation that references model `m` and field `f`.
- `D(m)` denotes `DeleteModel(name=m)`.
- `E` denotes an operation whose inherited `elidable` behavior applies.
- Other operations are modeled only by whether inherited `ModelOperation.reduce()` treats them as pass-through or as a boundary.

The value payloads `v` are opaque sets of field tuples. The proof needs equality of values only to identify "earlier" and "later" same-option operations; it does not inspect tuple contents.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | prompt issue | "Optimize multiple AlterFooTogether operations into one" | Repeated together-option operations that leave only a later final value should be reduced. | Encoded by PO-3 and PO-4. |
| INT-2 | prompt issue | "AlterFooTogether (AlterUniqueTogether and AlterIndexTogether)" | The family under audit is exactly unique-together and index-together, not all model options. | Encoded by PO-2 and PO-6. |
| INT-3 | prompt issue | "First, a migration will have operations to remove constraints, and then other operations adds the new constraints. This allows field alterations to work as expected during in between operations." | Removals/additions can collapse only when no intervening operation that must remain a field/model boundary blocks them. | Encoded by PO-5. |
| INT-4 | prompt issue | The example `[U(m,set()), I(m,set()), U(m,{col}), I(m,{col})]` "should be optimized to" `[U(m,{col}), I(m,{col})]`. | The opposite together option must be transparent enough for the same-option removal/addition pairs to meet in the optimizer. Final output order for the shown family is `U` then `I`. | Encoded by PO-4. |
| INT-5 | optimizer code comment | Optimizer returns "a list of equal or shorter length" and stops at boundaries "which can't be optimized over". | `reduce()` must not create longer results or erase boundary semantics. | Encoded by PO-5 and PO-7. |
| INT-6 | existing operation contract | `ModelOptionOperation.reduce()` replaces same-class model-option changes with the later operation and preserves `DeleteModel` reduction. | The fix must not regress inherited same-option and delete behavior. | Encoded by PO-1 and PO-3. |
| INT-7 | base operation contract | `Operation.reduce()` handles elidable operations generically. | The override must preserve inherited non-false reductions before adding the new cross-option case. | Encoded by PO-1; V1 gap recorded as F-001. |
| INT-8 | schema/state implementation evidence | `state_forwards()` alters only `{self.option_name: self.option_value}`; schema editor has separate `alter_unique_together()` and `alter_index_together()` methods. | Unique-together and index-together are independent frame dimensions for this reduction. | Encoded by PO-6. |

## Intent-Only Contract

For an `AlterTogetherOptionOperation` instance `self`:

1. If inherited reduction returns a non-`False` result for `(self, operation)`, `self.reduce(operation, app_label)` must return that exact result.
2. If inherited reduction returns `False`, and `operation` is the other `AlterTogetherOptionOperation` type on the same model, `self.reduce()` must return `True`, meaning `self` can optimize across `operation`.
3. If inherited reduction returns `False`, and `operation` is not the other together option on the same model, `self.reduce()` must return `False`.
4. The exact issue sequence must optimize to the two later final operations: `[U(m, final_u), I(m, final_i)]`.
5. The fix must remain limited to `AlterUniqueTogether` and `AlterIndexTogether`; no broader model-option commutation is specified by public intent.

## Formal English Paraphrase

The K-style claims in `PROOF_OBLIGATIONS.md` assert:

- `reduceAT(self, op)` is parent-preserving: non-`False` inherited reductions are not overridden.
- `reduceAT(U(m, a), I(m, b)) = True` and `reduceAT(I(m, b), U(m, a)) = True` when the inherited result is `False`.
- `reduceAT(U(m, a), U(m, c)) = [U(m, c)]` and `reduceAT(I(m, b), I(m, d)) = [I(m, d)]` through inherited `ModelOptionOperation.reduce()`.
- `optimize([U(m,a), I(m,b), U(m,c), I(m,d)]) = [U(m,c), I(m,d)]`.
- A field operation that references the same model/field remains a boundary and prevents reducing a clearing together operation across a required field alteration.

## Adequacy Audit

All formal obligations above trace to public issue text or existing public operation contracts. The only implementation-derived part is the proof model's abstraction of operation values as opaque payloads; that abstraction is adequate because the issue's property depends on operation class, model identity, inherited reducer result, and relative list order, not on the internals of field tuple sets.

The V1 behavior that returned `True` before consulting `super().reduce()` was not justified by public intent because it could bypass inherited non-`False` reductions. That mismatch is recorded as F-001 and repaired in V2.
