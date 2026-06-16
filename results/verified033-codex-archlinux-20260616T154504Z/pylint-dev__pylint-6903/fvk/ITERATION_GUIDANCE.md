# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

No additional production source edits are justified by the FVK findings. V1
already satisfies the public intent obligations:

- `F-001` and `PO-2` justify the shares-path clamp.
- `F-002` and `PO-3` justify applying the same clamp to the quota path.
- `F-003` and `PO-5` justify the defensive `_cpu_count()` guard.
- `F-004` and `PO-7` justify not broadening this issue into malformed cgroup
  file handling.
- `F-005`, `PO-4`, `PO-6`, and `PO-8` justify preserving fallback and public API
  behavior.

## Recommended next tests

Do not edit tests in this task. A downstream test author could add:

- A shares case with `cpu.cfs_quota_us = -1` and `cpu.shares = 2`, expecting
  `_query_cpu()` or the `--jobs=0` path to choose `1`.
- A quota case with `cpu.cfs_quota_us < cpu.cfs_period_us`, expecting `1`.
- A defensive `_cpu_count()` case where the cgroup helper is mocked to return
  `0`, expecting `_cpu_count()` to return `1` rather than propagating zero.
- A no-cgroup-data case confirming the existing host/scheduler fallback remains
  unchanged.

## Commands to run later

The following commands were intentionally not run here:

```sh
cd fvk
kompile mini-python-cpu.k --backend haskell
kast --backend haskell pylint-cpu-spec.k
kprove pylint-cpu-spec.k
```

A later machine check should return `#Top` before using the proof to remove any
unit tests.
