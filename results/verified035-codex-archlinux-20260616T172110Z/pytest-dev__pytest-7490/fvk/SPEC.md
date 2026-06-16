# FVK Specification: dynamic xfail marker refresh

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

This FVK pass specifies the xfail cache and report path changed by V1 in
`repo/src/_pytest/skipping.py`. The full pytest runtime is outside this mini
model; the model keeps the observable axis relevant to the issue:

- the number of xfail markers currently visible on an item,
- the cached evaluated xfail value and the marker count at which it was cached,
- whether the call phase failed, passed, skipped, or raised `pytest.xfail`,
- whether `--runxfail` disables marker-based xfail report handling,
- the final call report outcome and `wasxfail` reason.

The abstraction is property-complete for the reported defect: a stale cache with
no active xfail and a refreshed cache with an active xfail produce different
report outcomes for the issue's failing assertion.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt / issue | "we can dynamically add an xfail to a test `request` object using `request.node.add_marker(mark)`" | Adding an xfail marker during an item run is in-domain public behavior. | Encoded |
| I2 | prompt / issue | "In 5.x this treated the failing test like a ... test marked statically with an `xfail`." | A failing call report with an active dynamic xfail marker should be xfailed, not a normal failure. | Encoded |
| I3 | prompt / issue | example `request.node.add_marker(mark); assert 0`, expected `XFAIL ... xfail` | The concrete report must be skipped/xfailed with reason `xfail`. | Encoded |
| I4 | prompt / issue | "With 6.0.0rc0 it raises" and displayed `F`/`AssertionError` | The pre-fix failed report is the bug symptom, not a behavior to preserve. | Finding FVK-F1 |
| I5 | source API docs | `Node.add_marker`: "dynamically add a marker object to the node" | Public marker APIs mutate the item's marker list; cache freshness must track later marker visibility. | Encoded |
| I6 | source marker docs | xfail marker supports `reason`, `run`, `raises`, `strict` | After refresh, existing xfail report semantics for failure, raises filtering, strict XPASS, and XPASS must be preserved. | Encoded |
| I7 | source option docs | `--runxfail`: "report the results of xfail tests as if they were not marked" | Report-time refresh must not re-enable xfail handling under `--runxfail`. | Encoded |
| I8 | source hook order | call report is made after `pytest_runtest_call` returns | A marker added during the call body can only affect the result if the report hook refreshes after the body. | Encoded |

## Intent Specification

For an item whose visible xfail marker set changes after the cached xfail
evaluation, the next xfail-sensitive phase must refresh the cached xfail value
before using it.

For the issue case:

1. Before the test body, no active xfail is cached.
2. During the test body, `request.node.add_marker(pytest.mark.xfail(reason="xfail"))`
   makes one active xfail marker visible.
3. The test body fails with an assertion error.
4. The call report is not already skipped, did not come from imperative
   `pytest.xfail`, and `--runxfail` is false.
5. The report hook refreshes xfail state and applies the existing xfail marker
   report branch.
6. The final call report is skipped/xfailed with `wasxfail == "xfail"`.

## Frame Conditions

The fix must preserve these pre-existing precedence rules:

- unittest unexpected-success handling still wins before marker-based xfail
  report handling,
- `--runxfail` still disables marker-based xfail report handling,
- imperative `pytest.xfail()` exceptions still use their existing branch,
- already-skipped reports remain skipped rather than being rewritten as xfailed,
- setup-time dynamic xfail markers still refresh before the call phase so
  `run=False` can prevent the call body when the marker is added before call.

No public signature, hook signature, marker object shape, or report object shape
is changed.

## Formalization Boundary

The `.k` artifacts model a state machine for the changed xfail cache/report
logic, not the full Python interpreter or full pytest plugin manager. This is an
explicit FVK MVP abstraction. It is adequate for this issue because the public
defect is exactly a state freshness bug between `Node.add_marker` and
`pytest_runtest_makereport`.
