# FVK Proof

Status: constructed, not machine-checked. No K commands, tests, Python code, or project code were run.

## Machine-Check Commands

These commands are recorded for a later environment with K installed:

```sh
kompile fvk/mini-xarray-chunks.k --backend haskell
kast --backend haskell fvk/xarray-chunks-spec.k
kprove fvk/xarray-chunks-spec.k
```

Expected machine-check result after the abstract semantics are accepted: `#Top`.

## Proof Summary

The proof target is partial correctness of metadata access: if the accessors return normally, they return the same chunk metadata mappings as before while preserving the no-load state. Termination is straightforward for finite iterables but is not machine-proved here.

## PO-001 Proof: `Variable.chunks`

V1 did not change `Variable.chunks`; it returns `getattr(self._data, "chunks", None)`. In the abstract semantics, this is the rule:

```k
rule <k> chunks(Var(DIMS, C, LOADED)) => C </k>
```

There is no transition that reads `data`, converts to an array, or changes `<loaded>`. Therefore a state with `<loaded> false` reaches the post-state with `<loaded> false`.

## PO-002 Proof: `Variable.chunksizes`

V1 binds `chunks = self.chunks`. By PO-001, this read is metadata-only.

Case split:

- `chunks is None`: the function returns `{}`.
- `chunks is not None`: the function returns `Frozen({dim: c for dim, c in zip(self.dims, chunks)})`.

The old materializing expression `self.data.chunks` is no longer present. In the abstract semantics, `NoChunks` rewrites to `.Map`, and `SomeChunks(CS)` rewrites to `zipDimsChunks(DIMS, CS)`, with `<loaded>` unchanged.

## PO-003 Proof: `get_chunksizes()`

Use induction over the finite iterable of variables.

Base case: before any variables are processed, the local `chunks` dict is empty and no materializing API has been called.

Inductive step: assume the invariant after a prefix. For the next variable `v`, V1 checks `v.chunks is not None`. By PO-001, this is metadata-only. If `v.chunks is None`, the prefix mapping and no-load property are preserved. If chunked, the function iterates over `v.chunksizes.items()`. By PO-002, that mapping is metadata-only and equals the zip of `v.dims` and `v.chunks`.

For each `(dim, c)`, either `dim` is absent and the mapping is extended with `dim -> c`, or `dim` is present. If present with the same chunk tuple, the mapping is unchanged. If present with a different tuple, the existing `ValueError` is raised before overwriting. This preserves both the old consistency behavior and the no-load property.

By induction, normal return is `Frozen(chunks)` over the full iterable, and all processed paths avoid `v.data`.

## PO-004 and PO-005 Proof

`Dataset.chunks`, `Dataset.chunksizes`, and `DataArray.chunksizes` still call `get_chunksizes()`. Their signatures and return shapes are unchanged. The inconsistency error text remains in `get_chunksizes()`. Therefore public callers inherit PO-003 without an API compatibility change.

## Adequacy and Residual Risk

The proof directly covers the issue trace's failing mechanism: `hasattr(v.data, "chunks")` is gone from `get_chunksizes()`, and `Variable.chunksizes` no longer uses `self.data.chunks`.

Residual risk:

- This is constructed, not machine-checked.
- The K model is an abstract mini-semantics for the chunk metadata accessors, not full Python.
- Test removal is not recommended without an actual `kprove` result.
- Performance beyond avoiding data materialization on this accessor path is not proved.
