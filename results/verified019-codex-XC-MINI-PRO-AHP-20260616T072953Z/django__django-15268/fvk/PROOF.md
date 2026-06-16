# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Claims Proved

The constructed proof covers the obligations in `PROOF_OBLIGATIONS.md`:

- PO-1: inherited non-`False` reductions are preserved.
- PO-2: `AlterUniqueTogether` and `AlterIndexTogether` on the same model are transparent to each other after inherited reductions fail.
- PO-3: same-option reductions still collapse to the later operation.
- PO-4: the public issue sequence reduces to the two final operations.
- PO-5: field-operation boundaries remain boundaries.
- PO-6: unique-together and index-together are independent frame dimensions.
- PO-7: optimizer stability and fix scope are preserved.

## Constructed Symbolic Proof

### Parent Preservation

V2 begins with:

```python
result = super().reduce(operation, app_label)
if result is not False:
    return result
```

By direct symbolic execution, any inherited result other than the literal `False` is returned before the cross-option branch is evaluated. This discharges PO-1 and fixes F-001.

### Cross Together-Option Transparency

After the parent result is exactly `False`, V2 evaluates:

```python
isinstance(operation, AlterTogetherOptionOperation)
self.name_lower == operation.name_lower
self.option_name != operation.option_name
```

For `U(m,a)` and `I(m,b)` with the same normalized model name, all three conditions hold, so `reduceAT(U(m,a), I(m,b))` returns `True`. The symmetric `I`/`U` case is identical. If any condition fails, V2 falls through to `False`, preserving boundary behavior. This discharges PO-2 and the scoped part of PO-7.

### Same-Option Replacement

For `U(m,a)` followed by `U(m,c)`, `ModelOptionOperation.reduce()` returns `[operation]` because `operation` is `self.__class__` on the same model. PO-1 returns that inherited list before the cross-option branch. The same reasoning applies to `I(m,b)` followed by `I(m,d)`. This discharges PO-3.

### Exact Issue Sequence

Let the input be:

```text
[U0, I0, U1, I1]
where
U0 = U(m, a)
I0 = I(m, b)
U1 = U(m, c)
I1 = I(m, d)
```

First optimizer pass:

1. `U0.reduce(I0) == True` by PO-2, so `right` remains `True`.
2. `U0.reduce(U1) == [U1]` by PO-3.
3. Because `right` is still `True`, `optimize_inner()` emits the in-between operation `I0`, then the replacement `U1`, then the remaining `I1`.
4. Intermediate result: `[I0, U1, I1]`.

Second optimizer pass:

1. `I0.reduce(U1) == True` by PO-2.
2. `I0.reduce(I1) == [I1]` by PO-3.
3. `optimize_inner()` emits the in-between operation `U1`, then the replacement `I1`.
4. Intermediate result: `[U1, I1]`.

Third optimizer pass:

There is no earlier same-option operation to collapse. The fixed point is `[U1, I1]`, which matches the issue's required output. This discharges PO-4.

### Field Boundary Preservation

For `U(m,a).reduce(F(m,f))`, the parent reducer remains `False` when `F` references the same model. The new branch is not entered because `F` is not an `AlterTogetherOptionOperation`, so the result is `False`.

For `[U(m,a), F(m,f), U(m,c)]`, even after `U(m,a).reduce(U(m,c))` returns `[U(m,c)]`, the optimizer can only perform the left reduction if every in-between operation returns `True` for `reduce(other)`. Existing `FieldOperation.reduce()` checks `operation.references_field(...)`; `AlterTogetherOptionOperation.references_field()` returns `True` for empty option values or when the later option includes the field. Thus the field operation remains a boundary for the case the issue says the split was designed to protect. This discharges PO-5.

### Frame Independence

`AlterTogetherOptionOperation.state_forwards()` writes only `{self.option_name: self.option_value}`. Therefore `U` updates only `unique_together`, and `I` updates only `index_together`.

`BaseDatabaseSchemaEditor.alter_unique_together()` computes deleted/created uniques from `old_unique_together` and `new_unique_together` only. `alter_index_together()` computes deleted/created indexes from `old_index_together` and `new_index_together` only. The schema-editor API boundary mirrors the state frame. This discharges PO-6 for the audited reduction.

## K-Style Claims

These are the abstract claims that would be placed in a mini semantics for later machine checking:

```k
// SPEC-PROVENANCE: INT-7, F-001, PO-1.
claim <k> reduceAT(Self, Op) => R ... </k>
  requires parent(Self, Op) =/=K FalseR
   ensures R ==K parent(Self, Op)

// SPEC-PROVENANCE: INT-1, INT-2, INT-4, PO-2.
claim <k> reduceAT(AT(unique, M, A), AT(index, M, B)) => TrueR ... </k>
  requires parent(AT(unique, M, A), AT(index, M, B)) ==K FalseR

// SPEC-PROVENANCE: INT-1, INT-2, INT-4, PO-2.
claim <k> reduceAT(AT(index, M, B), AT(unique, M, A)) => TrueR ... </k>
  requires parent(AT(index, M, B), AT(unique, M, A)) ==K FalseR

// SPEC-PROVENANCE: INT-4, PO-4.
claim <k> optimize(ListItem(AT(unique, M, A)) ListItem(AT(index, M, B)) ListItem(AT(unique, M, C)) ListItem(AT(index, M, D)))
      => ListItem(AT(unique, M, C)) ListItem(AT(index, M, D)) ... </k>
```

## Commands Not Executed

The task forbids K tooling. These commands are recorded for a future environment only:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/alter-together-reduce-spec.k
kprove fvk/alter-together-reduce-spec.k
```

Expected result after completing the mini semantics and running in an allowed environment: `#Top`.

## Test Guidance

No tests were run or modified. After machine checking, direct unit tests that assert PO-4-style optimizer reductions would be subsumed by the proof. Integration tests around autodetector ordering, field-alteration boundaries, and database backend behavior should be kept because this constructed proof abstracts over full migration execution.
