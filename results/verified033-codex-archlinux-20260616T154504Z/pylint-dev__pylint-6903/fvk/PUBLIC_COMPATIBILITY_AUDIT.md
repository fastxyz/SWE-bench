# Public Compatibility Audit

Status: pass.

## Changed symbols

| Symbol | Public compatibility status |
| --- | --- |
| `pylint.lint.run._query_cpu()` | Private helper. Signature and return type shape remain `int | None`; only zero results from cgroup arithmetic are clamped to `1`. |
| `pylint.lint.run._cpu_count()` | Private helper. Signature remains unchanged. It still returns an `int`; V1 adds a lower bound when cgroup data exists. |
| `pylint.lint.run.Run.__init__` | No signature change. The `jobs == 0` branch still auto-detects with multiprocessing available and falls back to `1` without multiprocessing. |

## Public callsites and overrides

`_query_cpu()` is called by `_cpu_count()`. `_cpu_count()` is called by
`Run.__init__` and imported by test support. No public override or virtual
dispatch signature is changed.

## Test files

No test files are modified. Any future test deletion should wait for a
machine-checked `kprove` result.
