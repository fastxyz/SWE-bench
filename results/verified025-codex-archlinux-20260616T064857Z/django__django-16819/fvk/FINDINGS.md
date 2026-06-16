# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and symbolic reasoning only.

## FVK-F1: V1 missed add/rename/remove composition

Input sequence:

```python
[
    AddIndex("Pony", Index(fields=["pink"], name="old_idx")),
    RenameIndex("Pony", new_name="new_idx", old_name="old_idx"),
    RemoveIndex("Pony", "new_idx"),
]
```

Observed in V1 by inspection:

- `AddIndex.reduce(RenameIndex(...))` fell through to
  `IndexOperation.reduce()`.
- Because `RenameIndex` references the same model, the pass-through result was
  `False`.
- The optimizer could not compose the newly added index with its rename, so the
  later `RemoveIndex("new_idx")` could not cancel the add.

Expected from intent:

- Adding an index, renaming that same just-added index, and removing the final
  name has no net index effect.
- The optimizer should first reduce add+rename to a single `AddIndex` with the
  final name, after which add+remove cancellation applies.

Classification: code bug in V1.

Resolution: fixed in V2 by cloning the added index, assigning
`operation.new_name`, and returning `[self.__class__(self.model_name, index)]`
so public subclasses preserve their operation class.

Linked obligations: PO-4, PO-7.

## FVK-F1b: Rename composition must preserve AddIndex subclasses

Input sequence:

```python
[
    AddIndexConcurrently("Pony", Index(fields=["pink"], name="old_idx")),
    RenameIndex("Pony", new_name="new_idx", old_name="old_idx"),
]
```

Observed in the first V2 edit by inspection:

- Returning `[AddIndex(...)]` would preserve final state but drop the public
  `AddIndexConcurrently` operation class and its concurrent database behavior.

Expected from compatibility:

- A reducer that composes a rename into an add should keep the concrete add
  operation class when that class shares the `AddIndex(model_name, index)`
  constructor contract.

Classification: compatibility bug in the first V2 edit; fixed before final.

Linked obligations: PO-6, PO-11.

## FVK-F2: Matching AddIndex/RemoveIndex cancellation is required

Input sequence:

```python
[
    AddIndex("Pony", Index(fields=["pink"], name="pony_pink_idx")),
    RemoveIndex("Pony", "pony_pink_idx"),
]
```

Observed before V1:

- `AddIndex` had no reducer for `RemoveIndex`, so the pair remained.

Expected from intent:

- The operations have no net effect on migration state or database schema and
  reduce to `[]`.

Classification: original code bug; fixed by V1 and retained by V2.

Linked obligations: PO-1, PO-2.

## FVK-F3: Unrelated-model operations must not block the reduction

Input sequence:

```python
[
    AddIndex("Pony", Index(fields=["pink"], name="pony_pink_idx")),
    AddField("Rider", "age", IntegerField()),
    RemoveIndex("Pony", "pony_pink_idx"),
]
```

Observed before V1:

- Index operations inherited the base `Operation.references_model()`, which
  conservatively returns `True`.
- The optimizer could not prove the middle operation was unrelated to the index
  operation and could stop before finding the remove.

Expected from intent and optimizer contract:

- Operations on models that do not reference `Pony` are safe pass-through points
  while searching for the matching `RemoveIndex`.

Classification: original code bug; fixed by V1 and retained by V2.

Linked obligations: PO-3.

## FVK-F4: Exact index-name matching is intentional

Input sequence:

```python
[
    AddIndex("Pony", Index(fields=["pink"], name="CaseSensitiveIdx")),
    RemoveIndex("Pony", "casesensitiveidx"),
]
```

Observed and expected:

- The pair must not reduce under this proof because `ProjectState.remove_index()`
  compares index names exactly.

Classification: confirmed boundary, not a code bug.

Linked obligations: PO-2, PO-8.

## FVK-F5: Same-model unrelated index/field commutation remains conservative

Example sequence:

```python
[
    AddIndex("Pony", Index(fields=["pink"], name="pink_idx")),
    AddIndex("Pony", Index(fields=["weight"], name="weight_idx")),
    RemoveIndex("Pony", "pink_idx"),
]
```

Observed in V2 by inspection:

- The middle same-model `AddIndex` still references `Pony`, so it remains an
  optimizer boundary.

Expected from public intent:

- The issue requires reducing `AddIndex`/`RemoveIndex`; it does not explicitly
  require same-model index independence analysis.

Classification: residual conservative limitation, not changed. A broader
optimization would need a field/expression dependency analysis for indexes.

Linked obligations: PO-9.

## FVK-F6: Proof is constructed, not machine-checked

No `kompile`, `kast`, `kprove`, Python, or Django test command was run.

Classification: verification process limitation required by the task, not a code
finding.

Linked obligations: PO-10.
