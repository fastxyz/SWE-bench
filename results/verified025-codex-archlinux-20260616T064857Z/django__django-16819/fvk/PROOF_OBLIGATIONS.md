# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Direct add/remove cancellation

For all canonical model names `M`, exact index names `N`, and index payloads
`P`, `AddIndex(M, Index(name=N, payload=P)).reduce(RemoveIndex(M, N))` returns
`[]`.

Source: I1.

Status: discharged by V2 `AddIndex.reduce()` first branch.

Findings: FVK-F2.

## PO-2: Exact index-name guard

The cancellation in PO-1 is allowed only when the added index name and removed
index name are exactly equal.

Source: I4.

Status: discharged by V2 `self.index.name == operation.name`.

Findings: FVK-F4.

## PO-3: Unrelated-model pass-through

For any index operation on model `M` and later operation `O`, if
`O.references_model(M, app_label)` is false, `IndexOperation.reduce(O,
app_label)` returns boolean `True`.

Source: I2, I3, neighboring `ModelOperation.reduce()` pattern.

Status: discharged by V2 `IndexOperation.reduce()`.

Findings: FVK-F3.

## PO-4: Add/rename composition

For all canonical model names `M`, exact index names `Old` and `New`, index
payloads `P`, and concrete add operation class `C` using the
`C(model_name, index)` constructor shape, `C(M, Index(name=Old,
payload=P)).reduce(RenameIndex(M, new_name=New, old_name=Old))` returns
`[C(M, Index(name=New, payload=P))]`.

Source: I1, I5. This obligation is needed so an add/rename/remove sequence can
reduce completely.

Status: V1 failed; V2 discharges it by cloning the index, assigning the new
name, and constructing `self.__class__(self.model_name, index)`.

Findings: FVK-F1.

## PO-5: Replacement length and optimizer stability

Each replacement returned by the new reducers is no longer than the original
two-operation window:

- `AddIndex + RemoveIndex => []`
- `AddIndex + RenameIndex => [AddIndex]`

Source: I3 and optimizer docstring.

Status: discharged by inspection of return values.

Findings: none.

## PO-6: Public API compatibility

The fix must not change migration operation constructors, deconstruction shape,
method signatures, or operation names.

Source: I6.

Status: discharged. V2 only adds/overrides optimizer protocol methods, uses
existing `Index.clone()`, and preserves the concrete add operation class for
rename composition.

Findings: none.

## PO-7: Index payload preservation during rename composition

The add/rename composition must preserve all index attributes other than `name`.

Source: I5 and `Index.clone()` API.

Status: discharged by `index = self.index.clone(); index.name =
operation.new_name`.

Findings: FVK-F1.

## PO-8: Non-matching add/remove must not reduce

If two operations target the same model but different exact index names,
`AddIndex.reduce(RemoveIndex)` must not return `[]`.

Source: I4.

Status: discharged by the exact-name branch guard and superclass same-model
boundary.

Findings: FVK-F4.

## PO-11: Public AddIndex subclass preservation

When composing an add operation with a rename, the replacement operation must
preserve the concrete add operation class for public subclasses with the same
constructor shape, including `AddIndexConcurrently`.

Source: I6 and public subclass `django.contrib.postgres.operations.AddIndexConcurrently`.

Status: discharged by using `self.__class__(self.model_name, index)`.

Findings: FVK-F1b.

## PO-9: Conservative same-model boundary

The proof does not require pass-through across same-model operations whose field
or index dependencies are not analyzed.

Source: base `Operation.references_model()` safety guidance.

Status: intentionally retained. This is a limitation, not a failed obligation.

Findings: FVK-F5.

## PO-10: Honesty gate

All proof results must be labeled constructed, not machine-checked, and no test
or K command may be executed in this session.

Source: task constraints and FVK verify.md honesty gate.

Status: discharged by process.

Findings: FVK-F6.
