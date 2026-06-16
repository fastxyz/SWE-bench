# FVK Specification: pylint-dev__pylint-6903

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

The audited units are the `--jobs=0` CPU auto-detection path in
`repo/pylint/lint/run.py`:

- `_query_cpu()`: derives an optional cgroup CPU count from quota/period or
  share files.
- `_cpu_count()`: combines an optional cgroup count with the host/scheduler CPU
  count.
- `Run.__init__`: when `jobs == 0`, assigns `linter.config.jobs` from
  `_cpu_count()` if multiprocessing is available, otherwise assigns `1`.

The proof abstracts file I/O into integer cgroup inputs. The intended in-domain
inputs are parseable integer cgroup values where `cpu.cfs_period_us > 0`,
positive quotas are represented by `cpu.cfs_quota_us > 0`, unlimited quota is
represented by `cpu.cfs_quota_us == -1`, and `cpu.shares > 0` when the shares
file is used. Malformed files, `open()` failures, and a zero cgroup period are
outside the public issue's stated behavior and remain unchanged.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Running pylint in Kubernetes Pod with --jobs=0 fails" | The `--jobs=0` auto-detection path must not produce a multiprocessing worker count that crashes. | Encoded by PO-5 and PO-6. |
| E2 | prompt | "`_query_cpu()` ... returns 0 ... multiprocessing needs a value > 0" | A cgroup-derived CPU count used for multiprocessing must be strictly positive. | Encoded by PO-1 through PO-6. |
| E3 | prompt | `cpu.cfs_quota_us = -1`, `cpu.cfs_period_us = 100000`, `cpu.shares = 2`; calculation `2/1024` cast to `int` became `0`. | The shares branch with `cpu.shares = 2` must return `1`, not `0`. | Encoded by PO-2. |
| E4 | prompt | "The calculated number should never be 0." | Any in-domain auto-detected worker count must satisfy `jobs >= 1`. | Encoded by PO-1, PO-5, PO-6. |
| E5 | prompt | "I'm not sure if the same can happen for the calculation in line ... L55." | The quota/period branch must also be guarded against fractional values below one CPU. | Encoded by PO-3. |
| E6 | source help text | `jobs`: "Specifying 0 will auto-detect the number of processors available to use." | For `jobs == 0`, Pylint should replace zero with an available processor count rather than pass zero onward. | Encoded by PO-6. |
| E7 | implementation/comment frame | `_cpu_count()` already selected `min(cpu_share, cpu_count)` when cgroup data existed. | Preserve the existing cap by host/scheduler count while adding a positive lower bound. This is a compatibility frame, not the source of the bug-fix obligation. | Encoded by PO-5. |

## Intent-First Contract

1. If cgroup CPU shares are present and positive, `_query_cpu()` returns
   `max(1, int(cpu_shares / 1024))`. Therefore the reported Kubernetes value
   `cpu_shares = 2` returns `1`.
2. If a positive cgroup CPU quota and positive period are present,
   `_query_cpu()` returns `max(1, int(cpu_quota / cpu_period))`.
3. If no usable cgroup quota/share value is present, `_query_cpu()` returns
   `None`; the host/scheduler fallback remains responsible for the final count.
4. If `_cpu_count()` receives a cgroup count, it returns
   `max(1, min(cpu_share, cpu_count))`; if there is no cgroup count, it returns
   the host/scheduler count. With the standard host-count precondition
   `cpu_count >= 1`, the result is always at least `1`.
5. If `Run.__init__` handles `jobs == 0`, the value ultimately assigned to
   `linter.config.jobs` is at least `1` whether multiprocessing is available or
   not.
6. Existing behavior for negative `jobs`, positive nonzero `jobs`, and absent
   cgroup data is preserved.

## Formal Core

The compact K model is written in:

- `fvk/mini-python-cpu.k`
- `fvk/pylint-cpu-spec.k`

The model captures the arithmetic and branch behavior relevant to the bug:
truncating integer division, `max(1, value)`, `min(cpu_share, cpu_count)`, and
the two `jobs == 0` multiprocessing branches. It does not model filesystem
exceptions or full Python object state because those are outside the issue's
observable failure and are not changed by the fix.

Exact commands to machine-check later, not run in this session:

```sh
cd fvk
kompile mini-python-cpu.k --backend haskell
kast --backend haskell pylint-cpu-spec.k
kprove pylint-cpu-spec.k
```
