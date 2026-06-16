# Iteration Guidance

Status: V1 stands unchanged.

## Code Decision

No V2 production-code edit is recommended. Findings F1 and F2 are fixed by the
V1 helper-level change, and PO1-PO7 are discharged by the constructed proof and
source inspection.

## Why No Additional Code Change

- Adding a setitem-only special case would miss the scalar construction
  obligation in F2/PO3.
- Adding `pd.Index` to the explicit `.values` tuple would disturb the existing
  earlier adapter branch covered by F3/PO5.
- Reintroducing any generic `.values` fallback would violate F1/PO1 and the
  explicit-type-checking intent in E7-E9.
- Expanding the fix to unknown third-party containers that expose `.values` but
  do not implement NumPy protocols would contradict the public finding that
  arbitrary `.values` objects must be storable as scalar objects.

## Future Tests to Add When Test Edits Are Allowed

- Assign an instance with a `.values` attribute into a scalar `.loc` selection
  of an object-dtype `DataArray`; assert the stored object is the instance.
- Construct `DataArray(instance_with_values, dims=[])`; assert the scalar data
  contains the instance rather than `instance.values`.
- Preserve frame behavior for `pd.Series`, `pd.DataFrame`, `xr.DataArray`,
  `pdcompat.Panel` where available, `pd.Index`, and `PandasIndexAdapter`.

## Commands to Run in a Real Verification Environment

The current task forbids running these, but they are the next verification
steps:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell xarray-variable-spec.k
kprove xarray-variable-spec.k
```

After that, run the relevant xarray test subset in a normal project environment.

## Stop Conditions

The FVK phase can stop with V1 unchanged because:

- no remaining code bug is listed in `FINDINGS.md`;
- every code-relevant obligation in `PROOF_OBLIGATIONS.md` is discharged or
  explicitly classified as a non-code proof/test boundary;
- `PUBLIC_COMPATIBILITY_AUDIT.md` has no unhandled public callsite or override.
