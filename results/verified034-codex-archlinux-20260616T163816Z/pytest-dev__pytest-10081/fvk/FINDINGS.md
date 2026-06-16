# FVK Findings

Status: constructed, not machine-checked. Findings use only public issue text, in-repo source/tests, V1 notes, and the FVK proof obligations.

## F-001: Pre-V1 delayed teardown guard omitted class-level unittest skip

Classification: code bug, resolved by V1.

Evidence: E-001 through E-004, PO-001, PO-004.

Input/state: `USEPDB = true`, `ASYNC = false`, `METHOD_SKIPPED = false`, `CASE_SKIPPED = true`.

Observed pre-V1 behavior by symbolic reconstruction: the old guard checked `not _is_skipped(self.obj)` only. Since the method is not skipped, pytest saved `self._testcase.tearDown` and installed a no-op. unittest then reported the class-level skip without calling teardown, but pytest item teardown later invoked the saved original, producing the issue's `NameError`.

Expected: no explicit delayed teardown is installed for a class-level skipped unittest test, so real `tearDown` is not called.

Status: V1 resolves this by adding `and not _is_skipped(self._testcase)`.

## F-002: V1 preserves method-level skip and non-skipped delayed teardown behavior

Classification: confirmation, no source edit justified.

Evidence: E-005 through E-009, PO-002, PO-003, PO-003b, PO-004.

Input/state A: `METHOD_SKIPPED = true`. V1 still fails the delay guard through `not _is_skipped(self.obj)`, so no explicit teardown is installed.

Input/state B: `USEPDB = true`, `ASYNC = false`, `METHOD_SKIPPED = false`, `CASE_SKIPPED = false`. V1 still passes the delay guard and later calls the saved teardown exactly once.

Status: no V2 source change is justified for these paths.

## F-003: `_is_skipped(self._testcase)` is adequate for class-level skip metadata

Classification: confirmation, no source edit justified.

Evidence: E-008, E-009, PO-004.

Reasoning: `_is_skipped` is a `getattr` check for `__unittest_skip__`. A `TestCase` instance observes class attributes by normal Python attribute lookup, and this same instance predicate style already appears in `_make_xunit_fixture`.

Status: V1's instance check is locally consistent and avoids a broader refactor.

## F-004: No public compatibility issue from V1

Classification: compatibility confirmation.

Evidence: PO-005 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

V1 does not change public signatures, callback protocols, node classes, hook names, or virtual dispatch arguments. It changes only an internal Boolean condition.

Status: no compatibility-motivated source change is needed.

## F-005: Machine checking and full Python semantics remain outside this run

Classification: proof capability gap / honesty gate, not a code bug.

Evidence: PO-006.

The K artifacts model the delayed-teardown decision fragment, not the complete Python interpreter, pytest runner, or stdlib unittest implementation. The proof is constructed but not machine-checked because the task forbids running K tooling.

Status: keep all tests; no test removal is recommended from this run.
