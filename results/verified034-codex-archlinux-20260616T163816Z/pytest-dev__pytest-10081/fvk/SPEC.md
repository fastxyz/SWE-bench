# FVK Specification

Status: constructed, not machine-checked. No test, Python, `kompile`, or `kprove` command was run.

## Target

Candidate under audit: V1 change in `repo/src/_pytest/unittest.py::TestCaseFunction.runtest`.

The audited observable is whether pytest's `--pdb` delayed-teardown machinery installs and later invokes an explicit saved `unittest.TestCase.tearDown` for skipped or non-skipped unittest tests.

## Intent Ledger Summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

E-001 through E-003 establish that class-level `unittest.skip` under `--pdb` must not execute `tearDown`; the reported `NameError` in `tearDown` is the defect.

E-004 and E-006 establish method-level skip parity: method-level skipped unittest tests already must avoid setup and teardown under `--pdb`.

E-005 and E-007 establish the frame condition that non-skipped unittest tests under `--pdb` still delay and eventually run `tearDown`.

E-008 and E-009 establish the local skip predicate mechanism: `_is_skipped(obj)` checks `__unittest_skip__`, and pytest already uses `_is_skipped(self)` on unittest instances for xunit setup/teardown skipping.

## Formal State Model

The K fragment in `fvk/mini-unittest-pdb.k` models four Boolean inputs:

- `USEPDB`: pytest `--pdb` is active.
- `ASYNC`: the async unittest branch is taken.
- `METHOD_SKIPPED`: the collected method carries unittest skip metadata.
- `CASE_SKIPPED`: the `TestCase` instance/class carries unittest skip metadata.

The observable state is:

- `explicit`: whether pytest saved the original `tearDown` for item teardown.
- `tdcount`: number of real user `tearDown` invocations caused by this fragment after `runtest` and pytest item teardown complete.

## Contract

For any class-level skipped test (`CASE_SKIPPED = true`), `tdcount` must remain `0` and `explicit` must end `false`.

For any method-level skipped test (`METHOD_SKIPPED = true`), `tdcount` must remain `0` and `explicit` must end `false`.

For a synchronous, non-skipped unittest test with `USEPDB = true`, `tdcount` must end `1`: unittest receives the no-op replacement during the test run, and pytest item teardown invokes the saved original exactly once.

For a synchronous, non-skipped unittest test with `USEPDB = false`, `tdcount` must end `1` through unittest's normal teardown path and `explicit` must remain `false`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims. `fvk/SPEC_AUDIT.md` compares those claims against `fvk/INTENT_SPEC.md` and marks each as PASS.

The model is intentionally smaller than full Python and pytest. It keeps the property axis under verification: whether the delayed-teardown flag is installed and whether real `tearDown` is called. A failing pre-V1 class-skip case and a passing V1 class-skip case map to different `tdcount` values, so the abstraction does not collapse the defect.
