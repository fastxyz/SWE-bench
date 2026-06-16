# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decisions for V2

1. Keep the V1 `DataArray.loc` repair:
   `self.data_array.sel(key)`.
   This is justified by `FVK-F1` and `PO-2`/`PO-3`.

2. Apply the same mapping-form dispatch to
   `repo/xarray/core/computation.py`:
   `obj.sel({dim: value})`.
   This is justified by `FVK-F2` and `PO-4`.

3. Apply the same mapping-form dispatch to
   `repo/xarray/core/groupby.py`:
   `other.sel({self._group.name: group_value})`.
   This is justified by `FVK-F2` and `PO-4`.

4. Do not change `DataArray.sel` or `Dataset.sel` signatures.
   This is justified by `FVK-F3`, `PO-5`, and `PO-6`.

## Recommended Tests for a Future Executable Environment

Do not edit tests in this benchmark task. In a normal development pass, add or
keep tests for:

- explicit dict `.loc` selection on a dimension named `method`;
- positional `.loc` selection on a dimension named `method`;
- dimensions named `tolerance` and `drop`;
- grouped binary/computation paths that dynamically select along a dimension
  named `method`;
- direct `.sel({"method": "a"})` to document the unambiguous direct `.sel`
  spelling.

## Machine-Check Follow-Up

When K is available:

```sh
cd fvk
kompile mini-python-loc.k --backend haskell
kast --backend haskell dataarray-loc-spec.k
kprove dataarray-loc-spec.k
```

Keep all tests until the proof is machine-checked and ordinary project tests
pass in a real execution environment.

## Remaining Open Questions

No source-blocking ambiguity remains for this issue. A broader library-wide
policy audit could examine other APIs that accept both indexer keyword
arguments and option keywords, but a grep over non-test package code found no
remaining `.sel(**...)` call sites after V2.
