# FVK Notes

## Decision

V1 stands unchanged. No additional source edit under `repo/` is justified by the
FVK audit.

## Trace to Findings and Proof Obligations

F-001 identifies the original defect as the missing reverse data-model hook.
PO-001 establishes that reverse order is required by public intent, and PO-003
establishes that V1's `return reversed(self.dict)` implements that hook. This is
why no replacement implementation is needed.

F-002 addresses the main alternative interpretation: reverse the raw constructor
input versus reverse the ordered set contents. PO-002 and PO-005 tie the correct
behavior to the existing deduplicated backing dictionary, so V1's delegation to
`self.dict` is preferable to any list-copy or raw-input strategy.

F-003 records the only runtime side condition for `reversed(self.dict)`. PO-006
discharges it using the local `repo/setup.cfg` metadata (`python_requires =
>=3.8`), so I kept the minimal dictionary delegation rather than adding a
compatibility fallback.

F-004 covers public compatibility. PO-004 shows the method is read-only, and
PO-007 shows the API change is additive. Because existing signatures and call
patterns are unchanged, no follow-up source changes are needed.

## Artifacts

The requested FVK artifacts are:

* `fvk/SPEC.md`
* `fvk/FINDINGS.md`
* `fvk/PROOF_OBLIGATIONS.md`
* `fvk/PROOF.md`
* `fvk/ITERATION_GUIDANCE.md`

The FVK formal core and adequacy files are also present:

* `fvk/mini-python-orderedset.k`
* `fvk/orderedset-reversed-spec.k`
* `fvk/INTENT_SPEC.md`
* `fvk/PUBLIC_EVIDENCE_LEDGER.md`
* `fvk/FORMAL_SPEC_ENGLISH.md`
* `fvk/SPEC_AUDIT.md`
* `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No tests, Python code, or K tooling were run.
