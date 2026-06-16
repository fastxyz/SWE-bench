# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Running pylint in Kubernetes Pod with --jobs=0 fails" | The auto-detection path must avoid the reported multiprocessing crash. |
| E2 | `benchmark/PROBLEM.md` | "`_query_cpu()` ... returns 0" and "multiprocessing needs a value > 0" | A worker count passed to multiprocessing must be positive. |
| E3 | `benchmark/PROBLEM.md` | `cpu.shares` was `2`, leading to `2/1024` cast to `0`. | Shares below `1024` still require at least one worker. |
| E4 | `benchmark/PROBLEM.md` | "The calculated number should never be 0." | All in-domain auto-detected counts must be `>= 1`. |
| E5 | `benchmark/PROBLEM.md` | "I'm not sure if the same can happen for the calculation in line ... L55." | Audit and protect the quota/period path too. |
| E6 | `repo/pylint/lint/base_options.py` | "`jobs`: Specifying 0 will auto-detect the number of processors available to use." | `jobs == 0` is an auto-detection request, not a request for zero workers. |
| E7 | `repo/pylint/lint/run.py` comments/control flow | `_cpu_count()` combines cgroup result with host CPU count through `min`. | Preserve the existing compatibility frame unless it conflicts with positivity. |
