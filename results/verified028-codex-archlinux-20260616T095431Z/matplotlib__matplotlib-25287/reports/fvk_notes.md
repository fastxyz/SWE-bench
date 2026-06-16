# FVK Notes

## Decision Summary

V1 stands unchanged.  The FVK audit found that the V1 helper and x/y axis
initializer changes discharge the public rcParam/style intent for offset text
colors, including the `"inherit"` fallback.  No additional production source
edit is justified by the findings.

## Decision Trace

- Kept `_get_tick_label_color()` in `repo/lib/matplotlib/axis.py`.
  - Justification: F-004 requires tick labels and offset text to use the same
    rcParam resolver.  PO-001 and PO-002 prove the helper's explicit-color and
    inherit branches; PO-005 proves it is shared with default tick labels.

- Kept the V1 `XAxis._init()` change.
  - Justification: F-002 identifies the pre-fix x-axis defect.  PO-003 proves
    that x-axis offset text now receives `_get_tick_label_color("xtick")`,
    which satisfies PO-001 for explicit label colors and PO-002 for inherit.

- Kept the V1 `YAxis._init()` change.
  - Justification: F-001 identifies the reported y-axis defect.  PO-004 proves
    that y-axis offset text now receives `_get_tick_label_color("ytick")`,
    which satisfies PO-001 for explicit label colors and PO-002 for inherit.

- Made no further code edits.
  - Justification: F-005 records no unresolved proof-derived code finding.
    PO-006 shows the diff preserves non-color axis behavior, and PO-007 shows
    no public compatibility break.  The proof scope covers both axes and both
    resolver branches named by the issue.

- Did not modify tests.
  - Justification: the task forbids test changes.  `fvk/ITERATION_GUIDANCE.md`
    lists future tests that would cover F-001, F-002, and F-003 without changing
    the fixed hidden suite in this benchmark.

## Verification Caveat

The FVK proof is constructed, not machine-checked.  The required commands are
recorded in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`, but no K tooling was
run in this session.
