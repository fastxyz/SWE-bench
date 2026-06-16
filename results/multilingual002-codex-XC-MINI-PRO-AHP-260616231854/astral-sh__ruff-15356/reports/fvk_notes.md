# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the source edit directly discharges the issue-local obligations and did not surface a justified additional code change.

## Trace to Findings and Obligations

- Kept the `TokenKind::Equal` transition for `InTypeAlias(BeforeTypeParams)` because F-01 shows it localizes the reported false positive, and PO-01 through PO-03 formalize the required state transition and `E252` branch result.
- Did not add diagnostic deduplication because F-02 explains that duplicate-looking diagnostics are legitimate when both sides of a real annotated-parameter or type-parameter `=` are missing whitespace; PO-04 preserves that path.
- Did not broaden the source edit beyond `DefinitionState` because F-03 and PO-04/PO-05 show actual type-parameter behavior remains intact, while F-04 and PO-07 show no public API or compatibility change is required.
- Did not run tests or K tooling because the task forbids execution. F-05 records this as a proof-status caveat, and `fvk/PROOF_OBLIGATIONS.md` plus `fvk/PROOF.md` record the exact commands for a future machine check.

## Source Changes in This FVK Pass

No source files under `repo/` were changed during the FVK pass. The only new files are FVK artifacts under `fvk/` and this report.
