# Intent Specification

This file is intent-only: it is derived from the public issue text, public source
comments/docstrings, and named pytest option behavior, not from V1 as the
expected behavior.

1. A test may dynamically add an xfail marker to its own item using
   `request.node.add_marker(mark)`.
2. If that dynamically added xfail marker is active by the time the call report
   is made, a failing test body should be reported like an xfail-marked test,
   not as a normal failure.
3. The issue's concrete example must report an xfail with reason `xfail`.
4. The pytest 6 failure output in the issue is a bug symptom and must not be
   preserved as the expected result.
5. Existing xfail marker semantics for `reason`, `raises`, `strict`, XPASS, and
   `run=False` where the marker is present before call execution should remain
   governed by the existing xfail report/call logic.
6. `--runxfail` should continue to report xfail tests as if not marked.
7. The fix should not change public marker APIs, hook signatures, or report
   object shape.
