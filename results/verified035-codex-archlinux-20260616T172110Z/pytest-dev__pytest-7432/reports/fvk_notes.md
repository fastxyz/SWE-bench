# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original bug as F1 and did not
surface an additional source defect in the audited behavior.

## Trace to findings and obligations

F1 identifies the pre-fix root cause: the standalone `runxfail` branch in
`pytest_runtest_makereport` made the marker-skip location rewrite unreachable
under `--runxfail`. V1 addresses that by guarding only the xfail-specific
branches with `not item.config.option.runxfail`. This is the code change needed
for PO2.

F2 confirms that the resulting branch structure satisfies the remaining frame
obligations. PO3 is satisfied because xfail-specific rewrites still do not run
when `runxfail` is true. PO4 is satisfied because when `runxfail` is false the
new guard simplifies to `True`, leaving the original xfail predicates intact.
PO5 is satisfied because the existing `skipped_by_mark_key` and skipped tuple
checks still gate the item-location rewrite.

PO1 is handled by the intent-first artifacts: `INTENT_SPEC.md`,
`PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.
They classify the pre-fix `_pytest/skipping.py` location as the reported
symptom, not as intended behavior.

PO6 required checking public compatibility. `PUBLIC_COMPATIBILITY_AUDIT.md`
records that no public hook signature, option, report attribute, or store key
changed.

F3 and PO7 record the honesty constraint: the proof is constructed, not
machine-checked. The current task forbids running `kompile`, `kprove`, tests,
or Python, so no commands were executed.

## Changes made in this FVK pass

No source files under `repo/` were changed during the FVK pass. I added the FVK
artifacts under `fvk/` and this explanatory report.

## Alternatives considered

I considered a minimal refactor to store `item.config.option.runxfail` in a
local variable before the condition chain. The FVK findings did not justify that
edit: it would not discharge a new obligation, and the existing V1 code already
maps directly to PO2 through PO5.

I also considered moving the marker-skip rewrite ahead of the xfail branches.
That would satisfy PO2 but weakens PO4's preservation argument because it changes
branch order for non-runxfail reports. V1's narrower guard change keeps the
normal ordering intact.
