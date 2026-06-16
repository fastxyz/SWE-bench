# FINDINGS.md

Status: constructed, not machine-checked.

## F-001: Boolean denominator collapsed before V1

- Classification: code bug, resolved by V1.
- Evidence: E2-E4, PO-1, PO-2.
- Input: data `[1., 1., 1.]`, mask `[True, True, True]`, weights
  `[True, True, False]`.
- Observed before V1: denominator path used boolean/boolean dot and produced
  `True`; weighted mean was reported as `2.0`.
- Expected: denominator is numeric `2`; numerator is `2`; mean is `1.0`.
- V1 status: resolved by casting the data operand to `int` before `dot` when
  both reducer operands are boolean.

## F-002: Shared reducer needed the bool/bool repair, not only sum_of_weights

- Classification: proof-derived scope finding, resolved by V1.
- Evidence: E5, PO-1, PO-3.
- Input family: any `_reduce(da, weights, ...)` call where both operands are
  boolean after skipna handling.
- Candidate concern: fixing only `_sum_of_weights` would satisfy the issue
  example but leave `_reduce` inconsistent with its own documented equivalence
  to `(da * weights).sum(...)` for boolean data and boolean weights.
- Expected: bool/bool products are summed as integer counts.
- V1 status: resolved because the guard lives in `_reduce`, before all dot-based
  weighted reductions.

## F-003: Mixed dtype behavior must remain framed

- Classification: compatibility/frame condition, satisfied by V1.
- Evidence: PO-5, PO-6.
- Input family: boolean data with numeric weights, numeric data with boolean
  weights, and numeric data with numeric weights.
- Expected: these paths should keep the existing dot behavior because the issue
  and proof obligation are specific to boolean/boolean dot semantics.
- V1 status: satisfied because the guard is conjunctive:
  `da.dtype.kind == "b" and weights.dtype.kind == "b"`.

## F-004: Proof status caveat

- Classification: proof capability/honesty gate.
- Evidence: FVK verify workflow and PO-7.
- Finding: the proof is constructed but not machine-checked. The exact commands
  are recorded in `fvk/PROOF.md`, but they were not run per task constraints.
- Required action: do not delete or weaken tests based on this FVK pass alone.

## Unresolved Findings

None for the public intent modeled in this FVK pass. Residual risk is limited to
the stated abstraction boundary: full xarray alignment, duck-array backends, and
dimension handling are framed by source inspection rather than executed or
machine-verified here.
