# FVK Notes

## Decision

V1 stands unchanged. The audit found that the source expression
`self[i, j - other.cols]` is the minimal correction required by the formal
right-frame obligation.

## Trace to findings and proof obligations

- F-001 traces the reported bug to the pre-V1 right-frame source index
  `j - pos - other.cols`. PO-6 requires right-side result entries to read from
  `self[i, j - other.cols]`, so the current V1 line directly discharges the
  defect.
- F-002 records that V1 satisfies the complete piecewise entry contract for
  normalized positions. PO-4, PO-5, and PO-6 cover the left frame, inserted
  block, and right frame respectively.
- F-003 identifies a test gap: existing visible tests do not cover nonzero
  right-side preservation. The task forbids test edits, so no test files were
  changed.
- F-004 and PO-8 found no public compatibility issue. The public method
  signature, dispatch shape, shape guard, and result construction protocol are
  unchanged.
- PO-10 covers the public null-matrix branch. It is unchanged by V1 and no
  finding ties it to the reported non-null insertion defect.
- F-005 records that the proof is constructed, not machine-checked. Per the task
  instructions, the K commands are written into the artifacts but were not run.

## Alternatives considered

I considered changing the public position normalization, sparse matrix
insertion, or the unused local variable in `_eval_col_insert`. None of those
changes is supported by `fvk/FINDINGS.md` or required by
`fvk/PROOF_OBLIGATIONS.md`, so they were rejected to keep the source patch
minimal and targeted.
