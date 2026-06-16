# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-level problem beyond the bug
V1 already fixed. This decision is grounded in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`:

- F-001 identifies the pre-V1 tuple/list-axis `ValueError` as the operative bug.
  V1 resolves it by removing that rejection. This discharges PO-001.
- F-002 identifies the multi-axis valid-count arithmetic as the critical
  correctness point. V1 computes `np.take(mask.shape, axis).prod()`, which
  discharges PO-002, and keeps the documented `valid_count < min_count` predicate,
  which discharges PO-003.
- F-003 records the regression obligation for single-axis and scalar/all-axis
  reductions. V1 preserves single-axis behavior because `np.take(...).prod()`
  equals the old one-axis shape lookup for an integer axis, and it leaves the
  scalar branch unchanged. This discharges PO-004 and PO-005.
- F-004 is a proof-scope limitation, not a code bug. It maps to PO-007 and
  requires keeping tests and labeling the proof as constructed, not
  machine-checked; it does not justify a source edit.

## Files Added

- `fvk/SPEC.md`: public intent ledger, intent-only spec, adequacy audit, and
  compatibility audit.
- `fvk/FINDINGS.md`: resolved bug finding, proof obligations framed as findings,
  and residual proof-scope limitation.
- `fvk/PROOF_OBLIGATIONS.md`: PO-001 through PO-007, including the no-change
  justification.
- `fvk/PROOF.md`: constructed proof sketch, K claim summary, and commands that
  were intentionally not run.
- `fvk/ITERATION_GUIDANCE.md`: decision that V1 stands, plus future test and
  machine-check guidance.
- `fvk/mini-nanops.k` and `fvk/nanops-min-count-spec.k`: minimal supporting K
  artifacts for the `_maybe_null_out` null/keep decision.

## Source Changes

No source files were changed during the FVK pass. The existing V1 source edit in
`repo/xarray/core/nanops.py` remains the complete production-code fix according
to PO-001 through PO-006.

## Alternatives Considered

- Editing higher-level reduction dispatch was rejected because PO-001 shows the
  public dimension-list input already reaches `nanops` as a tuple axis; the
  failure was localized to `_maybe_null_out`.
- Editing tests was rejected because the task forbids modifying test files.
- Broadening the patch to unrelated reduction documentation or API cleanup was
  rejected because no finding or proof obligation tied such a change to the
  public issue intent.
