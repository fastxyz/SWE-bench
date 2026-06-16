# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
Python, or K tooling were run.

## Claims proved on paper

The formal claims live in `fvk/quantile-attrs-spec.k` and use the semantics in
`fvk/mini-xarray.k`.

- VQ-KEEP-TRUE proves PO-1.
- VQ-KEEP-FALSE proves PO-2.
- VQ-KEEP-DEFAULT-TRUE and VQ-KEEP-DEFAULT-FALSE prove PO-3.
- DATASET-PASS-KEEP and DATASET-PASS-DROP prove PO-4 and PO-5 for the
  one-data-variable shape used by the `DataArray` temporary dataset route.
- DA-KEEP-TRUE and DA-KEEP-FALSE prove PO-6 and PO-7.

## Proof sketch

### Variable quantile

The `variableQuantile` semantic rule rewrites
`var(DIMS, DATA, ATTRS)` to a result with framed value
`quantileData(DATA, Q, DIM, INTERP)` and framed dimensions
`quantileDims(DIMS, Q, DIM)`.

The only branch-sensitive result is attrs:

- if `KEEP` is `true`, `resolveKeep(true, G)` rewrites to `true`, and
  `keptAttrs(ATTRS, true)` rewrites to `ATTRS`;
- if `KEEP` is `false`, `resolveKeep(false, G)` rewrites to `false`, and
  `keptAttrs(ATTRS, false)` rewrites to `.Map`;
- if `KEEP` is `default`, `resolveKeep(default, G)` rewrites to the global
  option `G`, giving the corresponding true/false branch.

This discharges PO-1 through PO-3.

### Dataset quantile

The `datasetQuantile` semantic rule models a dataset with one reduced data
variable, the shape needed for the `DataArray._to_temp_dataset()` path. The
rule applies the same resolved keep flag to the data variable attrs and dataset
attrs. Therefore:

- `keep_attrs=True` preserves both variable attrs and dataset attrs;
- `keep_attrs=False` drops both attrs maps.

This discharges PO-4 and PO-5 for the attrs behavior under audit. Coordinate
and index handling are framed because the patch did not alter that code.

### DataArray quantile

The `dataArrayQuantile` semantic rule is the composition of:

1. a `DataArray` stores attrs on its variable;
2. the temporary dataset contains that variable;
3. dataset quantile reduces the variable with the resolved keep flag;
4. `_from_temp_dataset` returns the reduced variable as the new data array.

With `keep_attrs=True`, the result data array variable attrs are `ATTRS`; with
`keep_attrs=False`, they are `.Map`. This discharges PO-6 and PO-7 and covers
the issue MCVE.

## Adequacy and compatibility

The adequacy gate passed:

- `fvk/INTENT_SPEC.md` states the public behavior before accepting candidate
  behavior.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each K claim.
- `fvk/SPEC_AUDIT.md` maps each claim back to public evidence.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no broken public call shape.

## Residual risk

- This is partial correctness: it proves attrs on successful returns, not
  termination.
- Numeric percentile correctness is framed as `quantileData`; existing numeric
  tests remain necessary.
- The proof is constructed only. Machine-checking would require running K,
  which this task forbids.

## Commands to machine-check later

These commands are not executed in this task:

```sh
cd fvk
kompile mini-xarray.k --backend haskell
kast --backend haskell quantile-attrs-spec.k
kprove quantile-attrs-spec.k
```

Expected machine-check result after syntax/semantics validation: all claims
reduce to `#Top`.

## Test-redundancy recommendation

Do not delete any tests from this task. Existing visible quantile tests mostly
cover numeric values and shape behavior, which this attrs-focused proof frames
rather than proves. If the K artifacts are later machine-checked, an attrs-only
unit test for `DataArray.quantile(..., keep_attrs=True)` would be subsumed by
DA-KEEP-TRUE, but integration and numeric tests should remain.
