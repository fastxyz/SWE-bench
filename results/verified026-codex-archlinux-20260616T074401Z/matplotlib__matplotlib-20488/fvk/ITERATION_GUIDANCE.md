# FVK ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

Do not edit production code further. The FVK audit found that V1 discharges the
missing boundary case identified in F1 and PO3, while preserving the frame
conditions in F2, F3, PO4, and PO5.

## If Another Iteration Is Needed

Recommended checks to add or keep, without editing tests in this task:

- Keep `test_huge_range_log` because it covers integration behavior outside the
  local proof model.
- A focused unit-level regression could directly exercise the exact-zero
  temporary lower-limit case if the project has a suitable helper seam, but the
  current source does not expose that branch as a standalone public helper.
- Keep any tests for invalid user-specified `LogNorm` limits, because F4 and
  PO7 intentionally do not broaden valid input.

## Residual Risks

R1. The proof abstracts floating-point and masked-array behavior to the sign of
the temporary lower limit. It is adequate for the reported `vmin == 0` failure
mechanism but not a full renderer proof.

R2. The K artifacts are constructed but not machine-checked. Run the commands in
`fvk/PROOF_OBLIGATIONS.md` before treating the claims as machine-verified.

R3. Termination, performance, and backend-specific rendering are outside the
partial-correctness proof.
