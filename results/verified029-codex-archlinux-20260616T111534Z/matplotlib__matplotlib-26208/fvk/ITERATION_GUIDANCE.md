# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No V2 production edit is required. Findings F1 and F2, discharged by PO1-PO4,
show that V1 removes the late shared-unit broadcast that produced the reported
`ax1.dataLim` reset. Findings F3 and F5 argue against broadening the patch:
overwriting an already-unitized receiving axis would be a compatibility risk,
and changing `Axes.relim()` collection semantics is not required by the public
intent.

## What To Keep

- Keep the V1 `sharex()` unit-copy guard for receivers with no unit state.
- Keep the symmetric `sharey()` change.
- Keep `Axes.relim()` unchanged for this issue.

## Suggested Future Tests

Do not edit tests in this benchmark task. In a normal development branch, add a
regression test for:

- categorical `ax1.stackplot(...)`;
- `ax2 = ax1.twinx()` after the stackplot;
- categorical `ax2.plot(...)`;
- assertion that `ax1.dataLim.intervaly` remains the original stackplot y
  interval and `ax2.dataLim.intervaly` reflects the line data.

An analogous `twiny()` / shared-y case would be useful but is secondary to the
reported reproduction.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K model is intentionally abstract and does not verify full Matplotlib.
- No runtime validation was performed because the task forbids tests and code
  execution.
