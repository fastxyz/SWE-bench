# Formal Spec In English

## Claim `dynamic_xfail_body`

Start with an item whose xfail state was evaluated before the call body and no
active xfail marker was present. During the call body, add one active xfail
marker with reason `xfail`, then fail the call. When the call report is made
with `--runxfail` false, no imperative `pytest.xfail()` exception, and no prior
skip outcome, the report hook refreshes the cached xfail state, observes the new
marker, and produces a skipped/xfailed report with `wasxfail == "xfail"`.

## Frame/Precedence Claim

The refresh is only used for marker-based xfail handling. It does not override
unittest unexpected-success handling, `--runxfail`, imperative `pytest.xfail()`,
or already-skipped reports.

## Cache Freshness Claim

Whenever xfail state is cached for this path, the cache records both the
evaluated xfail value and the visible xfail marker count. A later count mismatch
means public marker APIs have made the cached xfail value stale.
