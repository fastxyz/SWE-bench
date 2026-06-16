# Findings

Status: constructed, not machine-checked.

## Summary

The FVK audit found no new source defect in V1. V1 satisfies the
intent-derived obligations in `fvk/PROOF_OBLIGATIONS.md`, so no source revision
is justified by this audit.

## F-001: Closed Code Bug - Skipped unittest Method Under `--pdb`

Classification: code bug, closed by V1.

Evidence: E-1, E-2; PO-1.

Input scenario: a `unittest.TestCase` test method decorated with
`@unittest.skip`, with a `tearDown` method that would raise if called, executed
by pytest with `--pdb`.

Observed before V1: pytest saved `tearDown` before unittest decided the method
was skipped, then pytest item teardown called that saved method, producing a
teardown error after the skip.

Expected: unittest reports the method as skipped and pytest performs no delayed
`tearDown` call for that item.

V1 result: the replacement `tearDown` records `_explicit_tearDown` only if
unittest actually calls the replacement. In the skipped path, unittest does not
call it, so `_explicit_tearDown` remains unset and pytest item teardown performs
no delayed `tearDown`.

Recommended source change: none beyond V1.

## F-002: Preserved Behavior - Reached TearDown Under `--pdb`

Classification: frame condition, confirmed.

Evidence: E-4, E-5; PO-2.

Input scenario: a unittest test method that reaches unittest teardown while
pytest runs with `--pdb`.

Observed before V1: pytest delayed the real `tearDown` and later ran it from
pytest item teardown.

Expected: this behavior must continue so postmortem debugging can inspect
pre-teardown instance state while still eventually running teardown.

V1 result: when unittest calls the replacement `tearDown`, V1 stores the
original bound method in `_explicit_tearDown`; pytest item teardown then calls
it exactly once.

Recommended source change: none.

## F-003: Compatibility Finding - No Public API Change

Classification: compatibility confirmed.

Evidence: PO-4 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Input scenario: public callers, hooks, and unittest result callbacks interacting
with `TestCaseFunction.runtest`, `TestCaseFunction.teardown`, and
`unittest.TestCase.tearDown`.

Observed in V1: no public signature changes. The temporary replacement
`tearDown` accepts `*args, **kwargs`, then records the original bound method for
later.

Expected: public pytest and unittest interaction shapes remain compatible.

Recommended source change: none.

## F-004: Verification Caveat - Proof Not Machine-Checked

Classification: proof capability gap.

Evidence: FVK instructions and PO-1 through PO-5.

Input scenario: relying on the proof artifacts without running the emitted K
commands.

Observed: this environment forbids `kompile`, `kast`, and `kprove`, so the proof
is constructed but not machine-checked.

Expected: keep tests and treat test-removal recommendations as conditional
until `kprove` returns `#Top` in an environment with K tooling.

Recommended source change: none. Recommended verification action: run the
commands in `fvk/PROOF.md` outside this restricted session.
