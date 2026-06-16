# FVK Notes

## Decision

V1 stands unchanged. No additional source edits were made.

## Trace to Findings and Proof Obligations

The decisive finding is F1: the old code repaired `s_vmin < 0` but let
`s_vmin == 0` reach `LogNorm`. PO3 requires the exact-zero case to be repaired,
and V1 already does that by changing the guard to `s_vmin <= 0` in
`repo/lib/matplotlib/image.py`.

F2 and PO4 require preserving already-positive temporary log limits. V1
satisfies this because the branch is skipped when `s_vmin > 0`, so no further
code change was justified.

F3, PO5, and PO6 require non-`LogNorm` behavior and public API compatibility to
remain unchanged. V1 satisfies this because the edit is inside the existing
`isinstance(self.norm, mcolors.LogNorm)` block and changes no public signature,
dispatch shape, return type, or storage format.

F4 and PO7 are why I did not broaden the fix to coerce all non-finite temporary
limits. The public issue concerns finite huge-range image data causing a
positive log `vmin` to collapse to zero during rescaling. A broader
`not np.isfinite(...)` repair could hide invalid caller-provided `LogNorm`
limits, which is outside the public intent.

F5 and PO8 are why I made no test-removal recommendation. The proof is local and
constructed, not machine-checked, and it does not cover renderer integration,
masked-array behavior, or backend drawing.

## Commands

The FVK commands are recorded in `fvk/PROOF_OBLIGATIONS.md` and `fvk/PROOF.md`.
They were not run, per the task instructions.
