# FVK Notes

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found the original crash mechanism and showed
that V1 removes it without creating a new source-level obligation.

## Trace from findings and obligations

Finding F-1 identifies the real bug: the pre-fix code treated the leaf sentinel
`-2` as a feature-name index. Proof obligations PO-2, PO-4, and PO-5 are the
corresponding safety requirements. V1 discharges them because
`feature_names[feature]` is now inside the split-node branch guarded by
`tree_.feature[node] != _tree.TREE_UNDEFINED`.

Finding F-2 records that no further production-code change is justified by the
audited public intent. PO-1 keeps the existing feature-name length validation,
PO-3 preserves split-label behavior for named and generic features, and PO-6
confirms that no public API or validation behavior changed.

Finding F-3 is a proof limitation rather than a code problem. PO-7 explains the
reduced K model and why it is adequate for the issue's pass/fail axis: it can
distinguish a bad lookup on `-2` from split-only lookup. Because the limitation
does not contradict any intent item, it does not justify another source edit.

## Code changes in this FVK pass

No files under `repo/` were changed during the FVK pass. The existing V1 edit in
`repo/sklearn/tree/export.py` remains the final source change.

## Artifacts produced

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional adequacy and formal-core artifacts required by the FVK docs are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-export-text.k`
- `fvk/export-text-spec.k`

No tests, Python, or K framework tooling were run.
