# FVK Notes

## Decision

V1 stands unchanged. I made no additional source edits after the FVK audit.

## Trace To Findings And Obligations

Finding FVK-F1 identifies the original defect as stale cached xfail state: the
issue input dynamically adds `pytest.mark.xfail(reason="xfail")` during the call
body, then fails, but the pre-fix report still used the earlier no-xfail cache.
PO1, PO4, and PO5 require the call report to refresh after a body-time marker
addition and then use the existing marker branch to produce an xfailed report.
V1 satisfies this through the report-time `_xfail_marks_changed(item)` check and
the subsequent `_evaluate_xfail_marks_with_store(item)` call.

Finding FVK-F2 justifies keeping the marker-count freshness design. PO2 requires
the cached xfail value to be paired with a freshness witness, and PO3/PO4 require
refresh when marker visibility changes before call execution or before call
report handling. `Node.add_marker` changes the visible marker list by appending
or inserting a `Mark`, so the count-based witness is adequate for the public API
path described by the issue.

Finding FVK-F3 covers non-regression risk. PO6 and PO7 require existing `raises`,
`strict`, XPASS, skip, imperative `pytest.xfail()`, unittest unexpected-success,
and `--runxfail` behavior to keep their precedence. V1 refreshes only the cached
xfail value and routes through the pre-existing report branch; the report-time
refresh is below the earlier special-case branches and inside `elif not
rep.skipped`.

Finding FVK-F4 is the audit conclusion: PO1 through PO8 are discharged by V1, so
no V2 source change is justified. The only residual limitation is FVK-F5/PO9:
the proof is constructed over the mini state-machine artifacts and was not
machine-checked because this task forbids K tooling and test execution.

## Artifacts Added

I wrote the five requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK artifact contract, I also wrote the adequacy and formal-core
artifacts under `fvk/`:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-pytest-xfail.k`
- `fvk/pytest-xfail-spec.k`

No tests were run or modified.
