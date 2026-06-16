# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "dynamically add an xfail to a test `request` object using `request.node.add_marker(mark)`" | Dynamic marker addition during a test is in scope. |
| E2 | `benchmark/PROBLEM.md` | "In 5.x this treated the failing test like a ... test marked statically with an `xfail`." | Active dynamic xfail should affect failing call report as xfail. |
| E3 | `benchmark/PROBLEM.md` | `request.node.add_marker(mark)` then `assert 0`; pytest 5 output `XFAIL ... xfail` | Concrete expected report is xfailed with reason `xfail`. |
| E4 | `benchmark/PROBLEM.md` | pytest 6 output displays `F` and `AssertionError` | Normal failure is the reported regression. |
| E5 | `repo/src/_pytest/nodes.py` | `add_marker`: "dynamically add a marker object to the node" | Public API mutates marker visibility. |
| E6 | `repo/src/_pytest/skipping.py` | xfail marker registration mentions `reason`, `run`, `raises`, `strict` | Preserve existing semantics for xfail options. |
| E7 | `repo/src/_pytest/skipping.py` | `--runxfail`: "report the results of xfail tests as if they were not marked" | Do not apply marker-based report rewrite under `--runxfail`. |
| E8 | `repo/src/_pytest/hookspec.py` / runner source | call report is produced after `pytest_runtest_call` | Body-time marker additions require report-time refresh. |
