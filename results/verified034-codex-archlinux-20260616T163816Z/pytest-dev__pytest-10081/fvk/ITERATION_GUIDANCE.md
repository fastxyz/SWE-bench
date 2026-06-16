# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No V2 source edit is justified by the FVK audit. V1 already adds the missing class/instance skip conjunct to the delayed-teardown guard while preserving the existing method-skip and non-skipped `--pdb` behavior.

## Trace To Findings And Obligations

F-001 / PO-001 show the original defect and why V1 resolves it.

F-002 / PO-002 / PO-003 / PO-003b show that the important frame conditions still hold: method-level skip still suppresses delayed teardown, non-skipped synchronous `--pdb` tests still run teardown once, and non-`--pdb` behavior stays normal.

F-003 / PO-004 justify keeping V1's chosen expression `_is_skipped(self._testcase)` rather than refactoring to a parent-class check.

F-004 / PO-005 show no compatibility-driven change is needed.

F-005 / PO-006 require keeping the proof honesty caveat and retaining tests until machine-checking is possible.

## Next Steps Outside This Task

When an execution environment is available, run the commands listed in `fvk/PROOF_OBLIGATIONS.md` and `fvk/PROOF.md` to machine-check the K fragment. Separately run the pytest test suite, including a regression test for class-level `unittest.skip` with failing `tearDown` under `--pdb`.
