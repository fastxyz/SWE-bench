# FVK Notes

## Decision

V1 stands unchanged.

The audit in `fvk/FINDINGS.md` found that V1 fixes the reported bug for the
intent-derived domain: real-valued windows in the PSD `scale_by_freq=False`
branch. `fvk/PROOF_OBLIGATIONS.md` PO1-PO3 require the coherent-gain
denominator `window.sum()**2`; V1 implements that exact expression.

## Source Changes

No additional source edits were made during the FVK pass.

The decision to keep `repo/lib/matplotlib/mlab.py` unchanged is traced to:

- `fvk/FINDINGS.md` F1, which classifies the V1 source as fixed for the
  negative-coefficient real-window case;
- `fvk/PROOF_OBLIGATIONS.md` PO2, which is satisfied by the existing V1
  `result /= window.sum()**2` line;
- `fvk/PROOF_OBLIGATIONS.md` PO4, which requires preserving the density branch
  and is satisfied because V1 did not edit that branch;
- `fvk/PROOF_OBLIGATIONS.md` PO7, which requires API/callsite compatibility and
  is satisfied because V1 changed no signatures or return shapes.

## Rejected Change: `np.abs(window.sum())**2`

I reconsidered replacing `window.sum()**2` with
`np.abs(window.sum())**2`. That would also fix real-valued negative windows and
may be a plausible policy for complex windows.

I rejected that change for this task because `fvk/FINDINGS.md` F3 and
`fvk/PROOF_OBLIGATIONS.md` PO6 classify complex-window behavior as
underspecified by the public issue. The public evidence supports removing the
coefficient-wise absolute value for real windows, not broadening the repair to
a complex-window policy.

## Tests and Execution

No tests, Python code, or K tooling were run. The K commands are recorded in
`fvk/PROOF.md` for later machine checking only.

No test files were modified. `fvk/FINDINGS.md` F4 records the remaining test
gap: a future regression test should cover a negative-coefficient real window
with `scale_by_freq=False`.
