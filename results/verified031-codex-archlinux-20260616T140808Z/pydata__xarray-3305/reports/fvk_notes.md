# FVK Notes

## Decisions

1. Keep the V1 semantic fix in `repo/xarray/core/variable.py`.
   - Reason: `fvk/FINDINGS.md` F1 identifies the root bug as attrs being lost
     at `Variable.quantile`, and F2 confirms the fix still respects false and
     default-false behavior.
   - Proof obligations: PO-1, PO-2, and PO-3 in
     `fvk/PROOF_OBLIGATIONS.md`.
   - Decision: no further semantic edit was needed in this file.

2. Keep the V1 semantic fix in `repo/xarray/core/dataset.py`.
   - Reason: F1 traces the `DataArray` failure through the temporary dataset
     route, and F4 finds no incompatible call shape from passing `keep_attrs`
     to variables.
   - Proof obligations: PO-4, PO-5, PO-6, PO-10, and PO-11.
   - Decision: no further semantic edit was needed in this file.

3. Change the `DataArray.quantile` docstring in
   `repo/xarray/core/dataarray.py`.
   - Reason: F3 found that V1 still said `keep_attrs` copies "dataset" attrs,
     while the public issue and source model concern `DataArray` variable attrs.
   - Proof obligation: PO-12.
   - Change made: updated the docstring to say "array's attributes".

4. Leave numeric quantile behavior, dimension handling, dask rejection,
   coordinate/index handling, and groupby dispatch unchanged.
   - Reason: `fvk/FINDINGS.md` records no open semantic finding on those paths;
     `fvk/PROOF.md` frames numeric value/dim behavior as outside the attrs
     defect, and `fvk/ITERATION_GUIDANCE.md` recommends no source changes there.
   - Proof obligations: PO-8 and PO-9.

## Formal artifacts

The FVK audit artifacts are under `fvk/`. The five requested files are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The additional FVK adequacy/formal-core files are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-xarray.k`
- `fvk/quantile-attrs-spec.k`

## Execution policy

No tests, Python code, or K tooling were run. The FVK proof is labeled
constructed, not machine-checked, and the emitted `kompile`/`kast`/`kprove`
commands in `fvk/PROOF.md` are for a later environment where execution is
allowed.
