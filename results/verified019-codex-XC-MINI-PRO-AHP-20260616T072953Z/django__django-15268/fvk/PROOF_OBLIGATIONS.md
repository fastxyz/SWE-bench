# FVK Proof Obligations

Status: constructed from public evidence, not machine-checked.

## Abstract Functions

`parent(self, op)` denotes the inherited `super().reduce(op, app_label)` result for `AlterTogetherOptionOperation`.

`reduceAT(self, op)` denotes the V2 implementation:

```text
result = parent(self, op)
if result is not False:
    return result
if same_model(self, op) and both_together_options(self, op) and option_name(self) != option_name(op):
    return True
return False
```

`optimize(xs)` denotes Django's repeated `MigrationOptimizer.optimize_inner()` loop.

## PO-1: Parent Preservation

For every `self`, `op`, and `app_label` in scope:

```text
parent(self, op) != False => reduceAT(self, op) == parent(self, op)
```

This preserves inherited elidable, same-option, delete, and different-model pass-through reductions.

## PO-2: Cross Together-Option Transparency

For every model `m` and option values `a`, `b`:

```text
parent(U(m,a), I(m,b)) == False => reduceAT(U(m,a), I(m,b)) == True
parent(I(m,b), U(m,a)) == False => reduceAT(I(m,b), U(m,a)) == True
```

For different models, PO-1 preserves inherited pass-through behavior. For same-option operations, PO-1 preserves inherited replacement behavior.

## PO-3: Same-Option Replacement

For every model `m` and option values `a`, `c`, `b`, `d`:

```text
reduceAT(U(m,a), U(m,c)) == [U(m,c)]
reduceAT(I(m,b), I(m,d)) == [I(m,d)]
```

This obligation is inherited from `ModelOptionOperation.reduce()` and protected by PO-1.

## PO-4: Exact Issue Sequence Reduction

For every model `m` and option values `a`, `b`, `c`, `d`:

```text
optimize([U(m,a), I(m,b), U(m,c), I(m,d)]) == [U(m,c), I(m,d)]
```

Constructed proof sketch:

1. `reduceAT(U(m,a), I(m,b)) == True` by PO-2.
2. `reduceAT(U(m,a), U(m,c)) == [U(m,c)]` by PO-3.
3. The optimizer performs the right reduction and returns `[I(m,b), U(m,c), I(m,d)]`.
4. `reduceAT(I(m,b), U(m,c)) == True` by PO-2.
5. `reduceAT(I(m,b), I(m,d)) == [I(m,d)]` by PO-3.
6. The optimizer performs the right reduction and returns `[U(m,c), I(m,d)]`.
7. A final pass has no earlier same-option operation to collapse, so the fixed point is `[U(m,c), I(m,d)]`.

## PO-5: Field Boundary Preservation

For any field operation `F(m, f)` that inherited reducer logic treats as a same-model or same-field boundary:

```text
reduceAT(U(m,a), F(m,f)) == False
reduceAT(I(m,b), F(m,f)) == False
```

For a sequence `[U(m,a), F(m,f), U(m,c)]`, the optimizer's left-reduction condition requires `F(m,f).reduce(U(m,c), app_label) is True`. Existing `FieldOperation.reduce()` returns `False` when the later together option references the same field, so the clearing operation cannot collapse across the field alteration.

## PO-6: Unique/Index Frame Independence

For a model state represented as a pair `(unique_together, index_together)`:

```text
state_forwards(U(m,u), (old_u, old_i)) == (u, old_i)
state_forwards(I(m,i), (old_u, old_i)) == (old_u, i)
```

Therefore the two operation types commute on model state:

```text
state_forwards(I(m,i), state_forwards(U(m,u), s))
==
state_forwards(U(m,u), state_forwards(I(m,i), s))
==
(u, i)
```

The database path has the same frame split at the schema-editor API boundary: `alter_unique_together()` receives only old/new unique-together values and `alter_index_together()` receives only old/new index-together values.

## PO-7: Optimizer Stability and Scope

The new reducer case returns only `True`, never a longer replacement list. Existing list replacements are inherited. Therefore the optimizer still returns an equal or shorter operation list and terminates on finite input under its existing fixed-point loop.

The new case is scoped to `AlterTogetherOptionOperation`, so it does not assert commutation for `AlterModelTable`, `AlterModelManagers`, `AlterModelOptions`, or `AlterOrderWithRespectTo`.
