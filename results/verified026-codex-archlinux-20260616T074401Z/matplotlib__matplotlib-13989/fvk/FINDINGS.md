# FVK Findings

Status: constructed, not machine-checked.

## F-001: Resolved bug, range dropped when density was added

- Classification: code bug, resolved by current V1 source.
- Evidence: E-001 through E-007; PO-001.
- Input class: non-empty single dataset, valid `range=(lo, hi)`,
  automatic bins, `density=True`, `stacked=False`.
- Pre-fix observed mechanism: `hist_kwargs['range'] = bin_range` was set, then
  `hist_kwargs = dict(density=density)` replaced the whole dictionary. The
  later `np.histogram` call therefore saw `density=True` but not the user
  range.
- Expected mechanism: `np.histogram` must see both `range=(lo, hi)` and
  `density=True`.
- Current V1 status: satisfied. The source now adds
  `hist_kwargs['density'] = density`, preserving the existing `range` entry.
- Code decision: keep V1 unchanged for this finding.

## F-002: Stacked density is a frame condition, not part of the bug

- Classification: compatibility frame condition, satisfied by current V1
  source.
- Evidence: E-009; PO-003.
- Input class: any single/empty path with effective density true and
  `stacked=True`.
- Expected mechanism: do not pass `density=True` to `np.histogram`; stacked
  density uses raw counts followed by the later manual normalization block.
- Current V1 status: satisfied because the assignment remains guarded by
  `if density and not stacked:`.
- Code decision: no additional edit. A broader change such as always passing
  `density` would violate this finding.

## F-003: Multiple-dataset range handling remains routed through common bins

- Classification: compatibility frame condition, satisfied by current V1
  source.
- Evidence: I-006; PO-004.
- Input class: multiple non-empty datasets with a specified range.
- Expected mechanism: common bin edges are computed by
  `histogram_bin_edges(np.concatenate(x), bins, bin_range, _w)` before the
  per-dataset histogram loop. Later per-dataset kwargs do not need a `range`
  entry.
- Current V1 status: satisfied. V1 does not alter the multiple-dataset branch.
- Code decision: no additional edit.

## F-004: Proof coverage is intentionally narrow

- Classification: proof coverage limitation, not a code bug.
- Evidence: SPEC coverage check; PO-006.
- Scope: the proof covers kwargs routing for `range` and effective density. It
  does not model NumPy internals, drawing, axes autoscaling, cumulative
  behavior, or log scaling.
- Recommendation: keep integration tests and add a focused regression test in
  the fixed test suite outside this task if allowed: assert that
  `hist(..., bins='auto', range=(0, 1), density=True)` returns bins whose first
  and last values are `0` and `1`.

## Proof-derived findings from `/verify`

No proof-derived code bug was found. The constructed proof obligations require
exactly the V1 behavior: preserve existing kwargs and add `density` without
replacing the dictionary. All proof obligations are discharged in the
constructed proof, subject to the MVP honesty gate that `kprove` was not run.
