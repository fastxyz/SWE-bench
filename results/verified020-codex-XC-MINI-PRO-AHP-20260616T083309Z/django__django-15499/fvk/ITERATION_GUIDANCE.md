# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found no open source-code finding. FVK-F1 through FVK-F4 are
closed by PO1 through PO7. FVK-F5 is a process limitation from the benchmark
environment and does not justify a source edit.

## Next Steps If Execution Becomes Available

Do not run these commands in this benchmark environment. If a K environment is
available later, machine-check the constructed proof with:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/create-model-reduce-spec.k
kprove fvk/create-model-reduce-spec.k
```

If the project test suite is editable in a later non-benchmark workflow, add a
focused optimizer regression test for:

- `CreateModel("Foo", managers=M0) + AlterModelManagers("Foo", managers=M1)`
  optimizes to `CreateModel("Foo", managers=M1)`.
- `M1=[]` empties the explicit managers.
- a different-model `AlterModelManagers` is not absorbed into the `CreateModel`.

## No Further Code Change

Do not refactor `ModelOptionOperation.reduce()` for this issue. The proof
obligations require constructing a replacement `CreateModel` with all constructor
arguments framed correctly, so the localized branch in `CreateModel.reduce()`
is the minimal source change.
