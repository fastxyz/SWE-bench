# Baseline Notes

## Root cause

`src/_pytest/skipping.py` rewrites reports for tests skipped by
`pytest.mark.skip` or `pytest.mark.skipif` so the skip location points at the
test item rather than the internal `skip()` call in pytest. In
`pytest_runtest_makereport`, the `--runxfail` branch returned early from the
conditional chain before that marker-skip rewrite could run. Because the
skip marker itself is evaluated during setup even when `--runxfail` is active,
the report stayed at the internal `_pytest/skipping.py` raise site.

## Files changed

`repo/src/_pytest/skipping.py`

Moved the `--runxfail` guard from a standalone "do not interfere" branch onto
only the xfail-specific report rewrites. This keeps `--runxfail` from changing
xfail outcomes while still allowing the existing marker-skip location rewrite
to run for skipped reports.

## Assumptions

The issue is limited to reporting for skips produced by skip/skipif markers,
not imperative `pytest.skip()` calls. The existing `skipped_by_mark_key` store
continues to distinguish marker-driven skips from other skips, so the fix should
not change locations for ordinary runtime skips.

I assumed `--runxfail` should still suppress only xfail-specific report
adjustments. This matches the option description and the reported behavior:
skip and skipif markers are independent of xfail handling.

## Alternatives considered

I considered moving the marker-skip rewrite before all xfail handling, but that
would risk changing reports for xfail exceptions if the marker flag were missing
or set unexpectedly. Guarding only the xfail branches is narrower and keeps the
existing ordering for normal runs.

I also considered changing report construction in `reports.py` so marked skips
start with the item location. That would spread marker-specific knowledge into
generic report creation, while the current module already owns skip/xfail marker
semantics.
