# Public-data reachability evidence (problem_statement + hints_text)

## hints_text (PUBLIC) — the dual-edged lure
```
Looks like a bug caused by a .query attribute change without performing a prior
copy() of the query/queryset.
Attaching a regression test that fails on master (... f3d3338e06 ...).
[PR]
Tests aren't passing.
Needs more tests, at the least. But discussion on PR suggests we've not hit the
right strategy yet.
```
- First line lures toward the clone/copy hypothesis (= V1's WRONG fix).
- Last two lines PUBLICLY ADMIT the copy strategy was tried and FAILED
  ("Tests aren't passing", "we've not hit the right strategy yet").
  => Public data both points at the wrong fix AND flags that it is wrong.

## problem_statement (PUBLIC) — the traceback localizes the symptom
The repro raises during SQL execution; traceback ends in
`django/db/models/sql/compiler.py ... execute_sql ... cursor.execute(sql, params)`
with the union ORDER-BY symptom. The public source of `get_order_by` (the combinator
positional-relabel block, with the inline comment "the columns can't be referenced by
the fully qualified name") contains the offending `raise`. So a reader can localize to
`get_order_by` from public issue + public source.

## Conclusion
Root cause is REACHABLE from public data alone: the existence/location of the
get_order_by defect is derivable from the traceback + public source; the hint even
warns the copy approach is the wrong strategy. The hidden FAIL_TO_PASS tests pin the
*precise* contract (still-raise-for-aliased via `if col_alias`), but are not needed to
discover the root cause.
