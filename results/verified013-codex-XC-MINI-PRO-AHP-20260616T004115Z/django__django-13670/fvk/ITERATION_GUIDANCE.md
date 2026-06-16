# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why No Source Revision Is Needed

- F-001 shows the legacy mechanism failed for `Y = 123`; OBL-003 shows V1
  computes the intended last-two-digits value by using `Y % 100`.
- F-002 shows the issue covers a boundary family; OBL-004 shows V1 covers that
  family uniformly across `1..9999`.
- F-003 shows ordinary behavior such as `1979 -> "79"` is preserved; OBL-005
  discharges that compatibility point.
- F-004 shows no public API or unrelated token behavior changed; OBL-006 and
  OBL-007 discharge the frame conditions.

## Changes Not Made

- Did not replace `%02d` with `zfill()` because OBL-003 is directly numeric:
  compute `Y % 100`, then render it as width two. V1 already states that
  contract clearly.
- Did not change `DateFormat.Y()` or docs because F-004 and OBL-007 show they
  are outside the defect and already align with the public token table.
- Did not add tests because the task forbids modifying test files.
- Did not run tests, Python, `kompile`, or `kprove` because the task forbids
  executing code or K tooling.

## Follow-up for a Normal Development Setting

If this were not a benchmark with fixed hidden tests, add public regression
tests for years `9`, `100`, and `123`. If K tooling is available later, run:

```sh
cd fvk
kompile mini-python-dateformat.k --backend haskell
kast --backend haskell dateformat-y-spec.k
kprove dateformat-y-spec.k
```

Keep any test-removal recommendation conditional on `kprove` returning `#Top`.
