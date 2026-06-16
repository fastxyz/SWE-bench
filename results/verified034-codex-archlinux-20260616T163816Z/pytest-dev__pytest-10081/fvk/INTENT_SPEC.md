# Intent Specification

Status: constructed from public evidence only; current implementation behavior is treated as the candidate to check.

## Required Behavior

I-001: A `unittest.TestCase` class decorated with class-level `unittest.skip` must be reported as skipped when collected and run by pytest.

I-002: For such a class-level skipped test, per-test `setUp`, the test method body, and per-test `tearDown` must not execute. The issue demonstrates `tearDown` raising `NameError` under `--pdb` as the bug to remove.

I-003: Enabling pytest `--pdb` must not change unittest skip semantics. It may delay `tearDown` for non-skipped unittest tests to preserve debug state, but it must not introduce a new teardown execution for skipped tests.

I-004: Existing method-level skip behavior must be preserved: method-level `@unittest.skip` under `--pdb` must not call `setUp` or `tearDown`.

I-005: Existing non-skipped `--pdb` behavior must be preserved: delayed `tearDown` still runs eventually for non-skipped unittest tests to avoid leaks and preserve debug usability.

## Domain

The formalized domain is the synchronous `TestCaseFunction.runtest` path that performs pytest's `--pdb` delayed-teardown decision, followed by `TestCaseFunction.teardown`. This is the path used by the public issue reproduction and the path changed by V1.

The async unittest branch is treated as a frame condition: V1 does not alter it, and the issue gives no async-specific obligation.

## Default-Domain Assumptions

D-001: Python attribute lookup on a `TestCase` instance observes class attributes such as `__unittest_skip__`. This matches the existing pytest pattern in `_make_xunit_fixture`, which calls `_is_skipped(self)` on a unittest instance.

D-002: The formal proof is partial-correctness only. It assumes `runtest` and pytest item teardown are reached by pytest's normal runner and does not prove runner scheduling or termination.
