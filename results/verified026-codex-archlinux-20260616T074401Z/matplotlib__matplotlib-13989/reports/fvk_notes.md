# FVK Notes

## Decision

V1 stands unchanged. No additional production source edit is justified by the
FVK audit.

## Traceability

- `fvk/FINDINGS.md` F-001 identifies the original bug as replacement of the
  whole `hist_kwargs` dictionary after `range` had been stored. `fvk/PROOF_OBLIGATIONS.md`
  PO-001 requires the single-dataset, non-stacked, effective-density path to
  produce kwargs containing both the original range and `density=True`. V1
  satisfies that by using `hist_kwargs['density'] = density` instead of
  replacing the dictionary.
- F-001 and PO-005 also justify keeping the same behavior for deprecated
  `normed=True`, because the source computes effective density from
  `density or normed` before the guarded kwargs update.
- F-002 and PO-003 justify not broadening the fix. Stacked density is manually
  normalized later in `Axes.hist`, so passing `density=True` to `np.histogram`
  on the stacked path would change existing semantics. V1 keeps the
  `not stacked` guard.
- F-003 and PO-004 justify not adding a `range` kwarg to the multiple non-empty
  dataset path. That branch already uses `bin_range` when computing shared bin
  edges with `histogram_bin_edges`.
- F-004 and PO-006 define the proof boundary. The FVK proof covers kwargs
  routing for `range` and effective density; it does not replace integration
  coverage for NumPy bin generation, drawing, unit conversion, autoscaling,
  cumulative histograms, or log scaling.

## Artifacts

The task-requested artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK documentation also requires the formal and adequacy core, so I added:

- `fvk/mini-hist-kwargs.k`
- `fvk/hist-kwargs-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification status

The proof is constructed, not machine-checked. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`, and I did not modify any
test files.
