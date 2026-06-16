# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

- F-001 identifies the pre-fix defect and PO-003 through PO-005 show V1 removes the exact failing condition: endpoint clipping no longer depends on `queryInterval.overlaps(holderInterval)`.
- F-002 and PO-006 show V1 preserves holder payloads, order, and cardinality.
- F-004 and PO-007 show the required "check other overlaps" audit did not surface another production source edit justified by the public issue.
- F-003 prevents claiming machine-checked verification or deleting tests, but it does not justify withholding the source fix.

## Recommended Next Steps Outside This Restricted Session

1. Run the emitted K commands in an environment with K installed.
2. Add a regression test for `lookup` with query `[T,T]` strictly inside a selected holder interval and assert the returned holder interval is `[T,T]`.
3. Run the relevant Druid timeline and query tests.

These steps are not performed here because the task forbids execution and test-file edits.
