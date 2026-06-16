# FVK Notes

## Decisions

1. Changed V1 truncation to rounded integer conversion in
   `repo/sklearn/cluster/optics_.py`.
   - Trace: `fvk/FINDINGS.md` F1 shows a concrete V1 mismatch
     (`0.26 * 10` truncates to 2 but rounds to 3).
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO2 and PO4 require the rounded
     expression for both `compute_optics_graph` and `cluster_optics_xi`.

2. Kept the V1 `compute_optics_graph` docstring update.
   - Trace: `fvk/FINDINGS.md` F2 explains the original float-neighbor failure.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO6 requires the public docstring to
     mention the accepted fractional form.

3. Did not broaden the patch to integer-valued floats above 1, such as
   `min_samples=5.0`.
   - Trace: `fvk/FINDINGS.md` F6 classifies that behavior as outside the
     documented issue domain and underspecified by the public evidence.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO1 limits this proof to values accepted
     by the intended documented domain and the fractional branch.

4. Did not edit tests or changelog files.
   - Trace: `fvk/FINDINGS.md` F5 records the benchmark constraint conflict.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO8 requires leaving those files alone.

5. Did not claim full OPTICS algorithm verification.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO9 explicitly marks graph ordering and
     clustering behavior as unchanged frame behavior, not formally proved.
   - Trace: `fvk/PROOF.md` records the proof as scoped and constructed, not
     machine-checked.

## Source Change Summary

The FVK audit produced one V2 source revision: replace direct integer
truncation with the public issue's rounded integer expression in all three
fractional size normalization sites. The fix remains minimal and source-only.
