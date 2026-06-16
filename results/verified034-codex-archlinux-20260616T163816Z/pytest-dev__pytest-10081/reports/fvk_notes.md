# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit identified the same root defect as the baseline pass and did not surface a source-level gap requiring V2.

## Source Decision

No additional edit was made to `repo/src/_pytest/unittest.py`.

This decision traces to F-001 and PO-001: V1's added `not _is_skipped(self._testcase)` conjunct prevents installing delayed teardown for class-level skipped unittest tests. It also traces to F-002, PO-002, PO-003, and PO-003b: the existing method-level skip check remains in place, non-skipped synchronous `--pdb` tests still install delayed teardown and call it once, and non-`--pdb` behavior stays normal.

The decision to keep `_is_skipped(self._testcase)` rather than refactor to `self.parent.obj` traces to F-003 and PO-004. Existing local code already uses `_is_skipped(self)` on a unittest instance for xunit setup/teardown skipping, and `_is_skipped` is intentionally a `getattr` check for `__unittest_skip__`.

The decision not to make compatibility edits traces to F-004 and PO-005. V1 changes only an internal Boolean condition and does not alter public signatures, hook protocols, node types, or virtual dispatch shapes.

## Artifact Decisions

Added the required FVK artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

Added the supporting adequacy and formal-core artifacts required by the FVK method: `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-unittest-pdb.k`, and `fvk/pytest-unittest-pdb-spec.k`.

The proof and K commands are labeled constructed, not machine-checked, due to F-005 and PO-006 and the task prohibition on running K tooling.

## Test Decision

No tests were modified or run. F-005 and PO-006 require keeping all tests because the proof was not machine-checked and the task forbids executing tests or K tooling.
