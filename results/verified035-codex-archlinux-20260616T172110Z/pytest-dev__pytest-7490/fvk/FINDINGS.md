# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations; no tests or
tooling were run.

## FVK-F1: stale cached xfail state caused the reported failure

Input: the issue's test body dynamically adds `pytest.mark.xfail(reason="xfail")`
and then fails with `assert 0`.

Observed pre-fix behavior from the issue: the call report is a normal failure
with an `AssertionError`.

Expected behavior from public intent: the call report is xfailed with reason
`xfail`, matching the displayed pytest 5 behavior.

V1 status: resolved. The report hook refreshes xfail state when the visible
xfail marker count changed during the call phase, so the existing marker-based
xfail report branch sees the dynamic marker.

Related obligations: PO1, PO2, PO4, PO5.

## FVK-F2: cache freshness must be keyed to marker visibility, not just phase

Input: xfail state was evaluated before the call body with zero xfail markers;
the call body then uses the public marker API to add an xfail marker.

Observed V1 mechanism: `_evaluate_xfail_marks_with_store` records both the
evaluated xfail state and `_xfail_mark_count(item)`. `_xfail_marks_changed`
compares the stored count with the current count.

Expected behavior: a public `add_marker` call makes the cache stale because
`Node.add_marker` appends or inserts a `Mark` into `own_markers`, and
`iter_markers(name="xfail")` will see the additional marker.

V1 status: resolved for public marker APIs. Direct manual mutation of
`own_markers` that replaces an xfail marker without changing count is outside
the public API modeled by this issue.

Related obligations: PO2, PO3, PO4, PO8.

## FVK-F3: existing report precedence must be preserved

Input: reports already handled by unittest unexpected-success, `--runxfail`,
imperative `pytest.xfail()`, or skip behavior.

Expected behavior: V1 must not use dynamic marker refresh to change those
outcomes.

V1 status: resolved. The report-time refresh sits inside the marker-based
`elif not rep.skipped` path, after unittest, `--runxfail`, and imperative
`pytest.xfail()` branches. Skipped reports remain skipped. The call hook keeps
the existing pre-call refresh path for setup-time dynamic markers and `run=False`.

Related obligations: PO6, PO7.

## FVK-F4: no additional source repair is justified by this audit

Input: V1 source in `repo/src/_pytest/skipping.py`.

Expected behavior: every public-intent obligation above is either discharged by
V1 or explicitly outside the public issue's domain.

V1 status: confirmed. The FVK audit did not find a source-level bug requiring a
V2 code edit.

Related obligations: PO1 through PO8.

## FVK-F5: proof remains constructed, not machine-checked

Input: this benchmark forbids running K tooling.

Expected behavior: artifacts must include commands and expected outcome, but not
claim machine-checked proof.

V1 status: residual verification risk. The proof is a constructed argument over
the mini state-machine semantics. Machine checking remains conditional on a
future allowed `kompile`/`kprove` run.

Related obligation: PO9.
