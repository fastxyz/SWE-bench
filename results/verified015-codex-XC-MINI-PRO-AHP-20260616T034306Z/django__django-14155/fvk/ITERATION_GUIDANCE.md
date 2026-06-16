# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source edits are required beyond V1. The FVK audit confirmed that V1 satisfies the intent-derived obligations for partial repr while preserving Django's documented `resolve()` triple and request-dispatch behavior.

## Why no V2 source change was made

- F-001 is the reported code bug, and it is discharged by PO-1 and PO-2.
- F-002 confirms the public runtime triple is preserved, discharging PO-4.
- F-003 confirms nested partials are included in the partial-chain behavior family, discharging PO-2.
- F-004 identifies a broader manual-constructor shape but records it outside the resolver-created domain described by the docs and source. It is not a blocker for this issue.
- F-005 records that proof/tool commands and tests were intentionally not executed.

## Recommended future work

1. Add public tests for partial repr once test edits are allowed.
2. Run the recorded K commands in an environment with K installed if a machine-checked FVK result is desired.
3. If Django wants `ResolverMatch` manual construction to be treated as a broad public API, separately decide whether to normalize non-tuple `args` in display metadata. That is outside this issue's public resolve-domain.
