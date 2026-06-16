# Formal Spec in English

The K claims in `pylint-cpu-spec.k` mean:

- `QUERY-SHARES-POSITIVE`: for every positive `SHARES`, the shares calculation
  returns `max(1, SHARES / 1024)` using truncating integer division, and the
  result is at least `1`.
- `QUERY-SHARES-REPORTED`: for the reported value `SHARES = 2`, the shares
  calculation returns `1`.
- `QUERY-QUOTA-POSITIVE`: for every positive quota `Q` and positive period `P`,
  the quota calculation returns `max(1, Q / P)` using truncating integer
  division, and the result is at least `1`.
- `QUERY-QUOTA-FRACTIONAL`: for every positive quota `Q` smaller than positive
  period `P`, the quota calculation returns `1`.
- `CPU-COUNT-SOME-POSITIVE`: when `_cpu_count()` has a cgroup count and a host
  count of at least `1`, it returns `max(1, min(cpu_share, cpu_count))`, and the
  result is at least `1`.
- `CPU-COUNT-ZERO-DEFENSIVE`: if the cgroup helper ever supplies `0` and the
  host count is at least `1`, `_cpu_count()` returns `1`.
- `CPU-COUNT-NONE-PRESERVES`: without a cgroup count, `_cpu_count()` returns the
  host count unchanged, assuming that count is at least `1`.
- `AUTO-JOBS-WITH-MP`: with multiprocessing available, the `jobs == 0` path
  assigns the positive `_cpu_count()` result.
- `AUTO-JOBS-NO-MP`: without multiprocessing, the `jobs == 0` path assigns `1`.
