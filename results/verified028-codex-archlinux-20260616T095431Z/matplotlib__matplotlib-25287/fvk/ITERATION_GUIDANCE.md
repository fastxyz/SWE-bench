# ITERATION_GUIDANCE.md

Status: V1 stands unchanged after FVK audit.

## Decision

Do not edit production code further for this issue.  The FVK findings identify
the pre-fix defect in both axis initializers and the inherit fallback
preservation requirement; V1 discharges those obligations with a shared private
resolver.

## Trace to Findings and Obligations

- F-001 is resolved by PO-001 and PO-004: y-axis offset text now uses explicit
  `ytick.labelcolor`.
- F-002 is resolved by PO-001 and PO-003: x-axis offset text now uses explicit
  `xtick.labelcolor`.
- F-003 is resolved by PO-002, PO-003, and PO-004: `"inherit"` still falls back
  to the corresponding tick color.
- F-004 is resolved by PO-005: default tick labels and offset text share the
  same rcParam resolver.
- F-005 is supported by PO-006 and PO-007: no source change beyond V1 is
  justified by the public intent or compatibility audit.

## Recommended Follow-Up Tests

Tests were not added because the task forbids modifying test files.  A future
maintainer-facing test patch should cover:

- `ytick.labelcolor` explicit color differs from `ytick.color`, and
  `ax.yaxis.get_offset_text().get_color()` equals the label color after a draw;
- `xtick.labelcolor` explicit color differs from `xtick.color`, and
  `ax.xaxis.get_offset_text().get_color()` equals the label color after a draw;
- both axes with `*.labelcolor == "inherit"` preserve fallback to `*.color`.

## Deferred Machine Check

The formal proof is constructed only.  To machine-check it later in an
environment with K installed, run:

```sh
kompile fvk/mini-axis-color.k --backend haskell
kast --backend haskell fvk/axis-offset-color-spec.k
kprove fvk/axis-offset-color-spec.k
```

Until the claims are machine-checked, do not remove any tests based on the FVK
proof.

## Next Iteration Input

If future public intent broadens the requested behavior beyond rcParam/style
initialization, run a new FVK pass over that broader contract.  This pass
confirms the V1 rcParam initialization fix only.
