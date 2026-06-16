# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and constructed proof obligations only.

## F-001: Shares branch rounded fractional CPU shares to zero

Classification: code bug, resolved by V1.

Input: `cpu.cfs_quota_us = -1`, `cpu.cfs_period_us = 100000`,
`cpu.shares = 2`, `--jobs=0`.

Observed before V1: `_query_cpu()` used `int(2 / 1024)`, returned `0`, and the
zero worker count reached `multiprocessing.Pool`.

Expected from public intent: the calculated worker count should never be `0`;
this case should produce at least `1`.

V1 status: resolved by `max(1, int(cpu_shares / 1024))`.

Proof obligations: PO-1, PO-2, PO-6.

## F-002: Quota/period branch had the same zero risk for fractional quotas

Classification: code bug, resolved by V1.

Input family: `cpu.cfs_quota_us = Q`, `cpu.cfs_period_us = P`, where
`0 < Q < P`.

Observed before V1: `_query_cpu()` used `int(Q / P)`, which evaluates to `0`
for a positive fractional CPU allocation below one full CPU.

Expected from public intent: the issue explicitly questioned whether the same
zero risk could happen in the quota calculation; the "never be 0" obligation
applies to both cgroup-derived paths.

V1 status: resolved by `max(1, int(cpu_quota / cpu_period))`.

Proof obligations: PO-1, PO-3, PO-6.

## F-003: `_cpu_count()` needed to enforce the positive-worker invariant

Classification: proof-derived needed guard, resolved by V1.

Input family: `_query_cpu()` returns an integer cgroup count and the host count
is available.

Observed before the defensive V1 guard: `_cpu_count()` returned
`min(cpu_share, cpu_count)`, so a zero cgroup count would propagate unchanged.

Expected from public intent: the final auto-detected worker count used for
`--jobs=0` must be at least `1`.

V1 status: resolved by `max(1, min(cpu_share, cpu_count))`.

Proof obligations: PO-5, PO-6.

## F-004: Malformed cgroup values remain outside this issue's domain

Classification: domain assumption, no source change.

Input family: non-integer cgroup file contents, unreadable cgroup files, or a
zero `cpu.cfs_period_us`.

Observed and expected: the public issue reports valid integer file contents and
a positive period. V1 intentionally does not change existing exception behavior
for malformed or impossible cgroup inputs because that would be a broader error
handling change without public intent evidence in this task.

Proof obligations: PO-7.

## F-005: No public compatibility issue from V1

Classification: compatibility audit, no source change.

Input/API surface: `_query_cpu()`, `_cpu_count()`, and `Run.__init__`.

Observed: V1 changes only return-value clamping in private helpers. It does not
change function signatures, command-line option names, output formats, or test
files.

Expected: `--jobs=0` should still auto-detect; absent cgroup data should still
fall back to the existing host/scheduler count; negative jobs should still be
rejected.

Proof obligations: PO-4, PO-6, PO-8.
