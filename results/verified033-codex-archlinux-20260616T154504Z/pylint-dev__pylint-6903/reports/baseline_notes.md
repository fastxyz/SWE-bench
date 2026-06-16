# Baseline Notes

## Root cause

`pylint.lint.run._query_cpu()` reads cgroup CPU quota/share values when `--jobs=0`
is used to auto-detect the available worker count. In containers where
`cpu.cfs_quota_us` is unlimited and `cpu.shares` is lower than `1024`, the
existing `int(cpu_shares / 1024)` calculation rounded the fractional value down
to `0`. `_cpu_count()` treated that `0` as a valid cgroup result and passed it
through to `multiprocessing.Pool`, which requires at least one process.

The same zero result could also occur in the quota/period path if the quota is a
positive fractional CPU allocation below one full CPU.

## Changed files

- `repo/pylint/lint/run.py`: Clamped both cgroup-derived CPU calculations to a
  minimum of `1` so `_query_cpu()` does not report zero workers when cgroup data
  is present but represents less than one full CPU. Also guarded `_cpu_count()`
  so an invalid zero from the cgroup helper cannot be propagated to the
  multiprocessing worker count.

## Assumptions and alternatives considered

- I assumed the intended behavior of `--jobs=0` is to auto-detect a positive
  worker count and that a fractional cgroup allocation should still allow Pylint
  to run with one worker instead of crashing.
- I considered clamping only in `_cpu_count()`, but rejected that as the sole fix
  because the invalid value is produced by `_query_cpu()` and direct callers of
  that helper should also receive a valid positive count when cgroup data is
  available.
- I considered changing the calculations to round up, but kept the existing
  rounded-down behavior for allocations above one CPU and only corrected the
  invalid zero case.
