# Proof Obligations

Status: constructed, not machine-checked.

## PO1: intent adequacy

The formal claim must express the public issue behavior, not the buggy pytest 6
output. Specifically, the issue reproduction with dynamic
`request.node.add_marker(pytest.mark.xfail(reason="xfail"))` followed by a
failing assertion must produce an xfailed call report with reason `xfail`.

Discharged by: `fvk/SPEC.md` I1-I4, `fvk/pytest-xfail-spec.k`
`dynamic_xfail_body`, and `fvk/SPEC_AUDIT.md`.

## PO2: stored xfail state includes a freshness witness

Whenever xfail marks are evaluated for cache use, the stored cache must include:

- the evaluated xfail result, and
- the visible xfail marker count at that evaluation point.

Discharged by: `_evaluate_xfail_marks_with_store`, which writes both
`xfailed_key` and `xfail_marks_key`.

## PO3: setup-time dynamic xfail markers still refresh before call execution

If marker count changes between setup evaluation and call hook entry, the call
hook must refresh before checking `run=False`, so fixture/setup-time dynamic
xfail behavior remains intact.

Discharged by: `pytest_runtest_call`, which refreshes when `xfailed is None` or
`_xfail_marks_changed(item)`.

## PO4: call-body dynamic xfail markers refresh before marker-based call report handling

If marker count changes during the call body, and the call report reaches the
normal marker-based xfail branch, the report hook must refresh before applying
xfail outcome rules.

Discharged by: `pytest_runtest_makereport`, which refreshes when
`call.when == "call"` and `_xfail_marks_changed(item)` inside the
`elif not rep.skipped` branch.

## PO5: issue failure becomes xfailed

For a call report with an assertion failure, `--runxfail == false`, no imperative
`pytest.xfail()` exception, not already skipped, and refreshed active xfail with
no `raises` mismatch, the report outcome must become skipped and `wasxfail` must
be set to the xfail reason.

Discharged by: the existing `if call.excinfo` marker branch after V1 refreshes
`xfailed`.

## PO6: existing xfail marker semantics are reused

V1 must not duplicate or weaken existing xfail semantics for `raises`, `strict`,
normal XPASS, and failure.

Discharged by: V1 only refreshes `xfailed`; the pre-existing branch still
performs `raises` filtering, strict XPASS failure, non-strict XPASS reporting,
and xfailed failure reporting.

## PO7: report precedence is preserved

The refresh must not alter outcomes already governed by unittest
unexpected-success, `--runxfail`, imperative `pytest.xfail()`, or skip reports.

Discharged by: refresh placement after those branches and inside
`elif not rep.skipped`; see Finding FVK-F3.

## PO8: public compatibility is preserved

The fix must not change public signatures or require call-site updates.

Discharged by: V1 adds private helpers and a private `StoreKey`; `Node.add_marker`,
`FixtureRequest.applymarker`, `pytest_runtest_call`, and
`pytest_runtest_makereport` signatures remain unchanged.

## PO9: honesty gate

Because this task forbids K tooling and test execution, the proof must be
reported as constructed, not machine-checked, and tests must not be removed.

Discharged by: `fvk/PROOF.md` commands and caveats; no tests were edited.
