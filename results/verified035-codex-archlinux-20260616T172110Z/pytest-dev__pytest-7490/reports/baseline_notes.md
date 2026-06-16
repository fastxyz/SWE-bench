# Baseline Notes

## Root Cause

Pytest 6 cached the evaluated xfail state during setup and reused that cached
value when building the call report. If no active xfail mark existed before the
test body ran, the cached value was `None`. A test could then call
`request.node.add_marker(pytest.mark.xfail(...))` during the body, but
`pytest_runtest_makereport` still saw the stale `None` value and reported the
failing assertion as a normal failure instead of an expected failure.

## Changed Files

`repo/src/_pytest/skipping.py`

Added tracking for the number of xfail markers present when xfail state is
evaluated. The setup and call hooks now store that count with the cached xfail
result, and the call report hook refreshes the xfail state if an xfail marker
was added while the test body was running. This keeps the existing cache for
unchanged marker sets while making dynamically added xfail markers visible to
the report logic.

## Assumptions

The issue is about xfail markers added through the public marker APIs during a
test or fixture. Those APIs add marker objects to the item, so a changed xfail
marker count is a sufficient signal that the cached xfail evaluation may be
stale.

I assumed `--runxfail` should continue to ignore xfail report handling. The
report-time refresh is therefore skipped in that mode.

## Alternatives Considered

Always re-evaluating xfail markers in `pytest_runtest_makereport` would also
fix the issue, but it would repeatedly evaluate unchanged xfail conditions and
increase the chance of side effects from condition expressions.

Invalidating xfail state directly from `Node.add_marker` would couple generic
node marker handling to the skipping plugin. The marker-count check keeps the
fix local to xfail handling.
