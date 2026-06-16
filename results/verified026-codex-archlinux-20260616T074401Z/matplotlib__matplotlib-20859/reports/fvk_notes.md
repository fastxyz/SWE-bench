# FVK Notes

## Decision

V1 stands unchanged.  The FVK audit did not identify a source defect requiring
a V2 edit.

## Trace to Findings and Proof Obligations

- The reported failure is `SubFigure.legend()` raising `TypeError`.  F-001
  identifies that as an in-domain rejection of a valid `SubFigure` parent.
  PO-001 and PO-002 discharge it because V1 checks `FigureBase`, and
  `SubFigure` is a `FigureBase`.
- Existing behavior for `Axes.legend()` and `Figure.legend()` was kept.  F-003,
  PO-003, and PO-004 show that the axes branch still runs first and concrete
  `Figure` remains accepted through `FigureBase`.
- Arbitrary direct `Legend` parents remain invalid.  F-004 and PO-004 show that
  V1 did not broaden the constructor beyond `Axes` plus figure-like
  `FigureBase` parents.
- The public bbox hint was re-audited rather than dismissed as scope.  F-002,
  PO-006, and PO-007 show that a legend created by `SubFigure.legend()` is
  owned by `subfig.legends`; `FigureBase.get_children()` includes legends; and
  top-level tight-bbox traversal reaches the `SubFigure`, whose own tight bbox
  includes its legend.  Therefore no `FigureBase.get_default_bbox_extra_artists`
  edit is justified by the proof obligations.

## Artifacts Written

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK method's formal-core and adequacy requirements, I also wrote:

- `fvk/mini-python-subfigure-legend.k`
- `fvk/subfigure-legend-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification Status

No tests, Python, or K tooling were run.  F-005 records the residual risk:
the proof is constructed, not machine-checked.  `fvk/PROOF.md` contains the
commands that should be run in an environment with K installed.
