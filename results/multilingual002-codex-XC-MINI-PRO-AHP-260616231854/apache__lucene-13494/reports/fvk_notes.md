# FVK Notes

## Decision

V1 stands unchanged after the FVK audit.

The audit found that the original defect is fully represented by the state where
`sparseCounts == null` and `denseCounts == null` after a valid no-hit collection.
`fvk/FINDINGS.md` records this as F-001 and F-003. `fvk/PROOF_OBLIGATIONS.md`
turns it into PO-001, the equivalence between `hasCountStorage() == false` and both
stores being null.

## Source Change Review

`repo/lucene/facet/src/java/org/apache/lucene/facet/StringValueFacetCounts.java`

- The V1 `getTopChildren` guard is kept because it discharges PO-002: after the
  existing validation passes, empty count storage returns `emptyResult()` before any
  `denseCounts.length` dereference. This resolves F-001.
- The V1 `getAllChildren` guard is kept because it discharges PO-003: the same
  empty count state returns an empty `FacetResult` before the dense loop. This
  resolves the related accessor gap in F-002.
- The V1 `getSpecificValue` guard is kept because it discharges PO-005 while PO-006
  confirms the absent-term `-1` behavior remains before storage is consulted. This
  resolves the specific-value part of F-002.
- No further source edit was made because PO-007 shows non-empty dense and sparse
  paths bypass the new guard and continue through the pre-existing counting logic.
  F-004 records this as the basis for keeping V1 unchanged.
- No API edit was made because PO-009 and the compatibility section in
  `fvk/SPEC.md` found no public signature, return type, constructor, or override
  change.

## Alternative Considered

The main alternative remains allocating a dense zero-filled count array for no-hit
searches. The FVK audit rejects that for the same reason as the baseline notes:
F-003 identifies empty storage as a valid representation, and PO-002/PO-003 prove
the public accessors can satisfy the zero-count intent without allocating dense
storage.

## Verification Status

The FVK proof is constructed, not machine-checked. The exact commands are written in
`fvk/SPEC.md` and `fvk/PROOF.md`, but they were not run because this task forbids
running K tooling or project code.

No tests were run and no test files were modified.
