# Proof Obligations

Status: constructed, not machine-checked. The obligations below are the audit
contract used to decide whether V1 stands.

## PO-1: Positive cgroup count invariant

For every in-domain cgroup-derived integer count returned by `_query_cpu()`,
the returned value must be at least `1`.

Evidence: E2, E4.

K claims: `QUERY-SHARES-POSITIVE`, `QUERY-QUOTA-POSITIVE`.

Status: discharged by construction.

## PO-2: Reported Kubernetes shares case

For `cpu.cfs_quota_us == -1` and `cpu.shares == 2`, the shares-derived count is
`1`, not `0`.

Evidence: E3.

K claim: `QUERY-SHARES-REPORTED`.

Status: discharged by construction because `max1Int(2 /Int 1024) = 1`.

## PO-3: Fractional quota case

For positive `Q` and `P`, where `P > 0`, the quota-derived count is
`max(1, int(Q / P))`; therefore if `0 < Q < P`, the result is `1`, not `0`.

Evidence: E4, E5.

K claims: `QUERY-QUOTA-POSITIVE`, `QUERY-QUOTA-FRACTIONAL`.

Status: discharged by construction.

## PO-4: Absent cgroup data preserves fallback

If `_query_cpu()` has no usable cgroup count and returns `None`, `_cpu_count()`
uses the host/scheduler count. With the standard host-count precondition
`cpu_count >= 1`, the result is unchanged and positive.

Evidence: E6 plus compatibility frame from unchanged control flow.

K claim: `CPU-COUNT-NONE-PRESERVES`.

Status: discharged by construction.

## PO-5: `_cpu_count()` cannot propagate zero from a cgroup helper result

If `_cpu_count()` receives any integer cgroup count and the host/scheduler count
is at least `1`, the result is `max(1, min(cpu_share, cpu_count))` and is at
least `1`.

Evidence: E1, E2, E4, E7.

K claims: `CPU-COUNT-SOME-POSITIVE`, `CPU-COUNT-ZERO-DEFENSIVE`.

Status: discharged by construction.

## PO-6: `--jobs=0` assigns a positive worker count

If `jobs == 0`, then `Run.__init__` assigns `linter.config.jobs >= 1`.
When multiprocessing is unavailable, the assigned value is `1`. When
multiprocessing is available, the assigned value is `_cpu_count()`, which is
positive by PO-4 and PO-5.

Evidence: E1, E2, E4, E6.

K claims: `AUTO-JOBS-WITH-MP`, `AUTO-JOBS-NO-MP`.

Status: discharged by construction.

## PO-7: Domain boundary is explicit

The proof domain is parseable integer cgroup data with positive period when the
quota branch is used. Malformed file contents, unreadable files, and zero
period are not silently proved correct.

Evidence: public issue gives valid integer files and a positive period; no
public intent requests broader cgroup error handling.

K representation: `requires SHARES >Int 0`, `requires Q >Int 0 andBool P >Int 0`.

Status: recorded, not a code-change obligation.

## PO-8: Public API and test suite compatibility

No public signatures, option names, output formats, or test files are changed.

Evidence: source diff and compatibility audit.

K representation: frame obligation outside arithmetic model; recorded in
`PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by inspection.
