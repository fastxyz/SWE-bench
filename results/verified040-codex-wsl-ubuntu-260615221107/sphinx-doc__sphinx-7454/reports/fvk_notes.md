# FVK Notes

## Source decision

No additional source edit was made. V1 stands because the FVK audit found the
issue-relevant defect and showed that the existing conditional exactly
discharges it.

The decision traces to `fvk/FINDINGS.md`:

- F-001 identifies the original signature-mode `None` class-role reference as
  the code bug and marks it resolved by V1.
- F-002 identifies the inconsistency with description mode and marks it
  resolved by V1.
- F-003 confirms the non-`None` frame condition.
- F-004 confirms the parser fallback path uses the same helper.
- F-005 confirms no public compatibility issue.
- F-006 records the proof honesty limitation but does not justify a source
  change.

The same decision traces to `fvk/PROOF_OBLIGATIONS.md`:

- PO-001 and PO-002 require the `None` object-role path and its intersphinx
  resolution.
- PO-003 and PO-004 require preserving class-role behavior for `int` and all
  other non-`None` tokens.
- PO-005 requires both parser branches to use the same corrected helper.
- PO-006 requires parity with the existing description-mode field behavior.
- PO-007 requires compatibility, which the V1 diff satisfies.
- PO-008 requires the constructed, not machine-checked, caveat.

## Artifact decisions

I wrote the five requested FVK artifacts under `fvk/` and also included the
formal K core as `fvk/mini-sphinx-annotation.k` and
`fvk/sphinx-7454-spec.k`, because the FVK documentation says a run without K
claims is unresolved. The commands to check those files are recorded in the
artifacts but were not executed.

## Test decision

No tests were run or modified, following the task constraints. Test guidance is
recorded in F-006, PF-002, PO-008, and `fvk/ITERATION_GUIDANCE.md`.
