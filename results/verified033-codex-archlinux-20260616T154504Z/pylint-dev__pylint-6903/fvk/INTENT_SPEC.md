# Intent Specification

Intent-only obligations derived from public evidence, before accepting candidate
implementation behavior:

1. `--jobs=0` means Pylint auto-detects a worker count; it must not pass `0` to
   multiprocessing.
2. The calculated auto-detected worker count should never be `0`.
3. The reported Kubernetes case with `cpu.cfs_quota_us = -1` and
   `cpu.shares = 2` must produce at least one worker.
4. The same zero-protection applies to the quota/period calculation when a
   positive quota represents less than one full CPU.
5. If multiprocessing is unavailable, the existing fallback to one worker should
   remain.
6. If no usable cgroup CPU data exists, the existing host/scheduler CPU-count
   fallback should remain.
7. The task does not request changed behavior for malformed cgroup files,
   unreadable files, or non-positive cgroup periods.
