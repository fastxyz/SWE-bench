# Spec Adequacy Audit

| Formal claim | Intent match | Rationale |
| --- | --- | --- |
| `QUERY-SHARES-POSITIVE` | pass | Matches E2, E3, E4: cgroup shares must not round to zero. |
| `QUERY-SHARES-REPORTED` | pass | Directly covers the public Kubernetes values from E3. |
| `QUERY-QUOTA-POSITIVE` | pass | Matches E4 and E5: the quota path must receive the same zero protection. |
| `QUERY-QUOTA-FRACTIONAL` | pass | Covers the specific fractional quota family raised by E5. |
| `CPU-COUNT-SOME-POSITIVE` | pass | Matches E1, E2, E4 and preserves E7's existing host-count cap. |
| `CPU-COUNT-ZERO-DEFENSIVE` | pass | A proof-derived guard needed to prevent the reported symptom from reappearing if the helper returns zero. |
| `CPU-COUNT-NONE-PRESERVES` | pass | Matches the compatibility frame in E6/E7; the issue does not request changing absent-cgroup fallback. |
| `AUTO-JOBS-WITH-MP` | pass | Matches E1, E2, E4, E6: `jobs == 0` auto-detection must assign a positive worker count. |
| `AUTO-JOBS-NO-MP` | pass | Preserves existing fallback behavior and satisfies E4. |
| Domain excludes malformed files and zero period | pass | The public issue supplies valid integer files and a positive period; broader cgroup I/O error handling is not part of the intent. |

No formal-English obligation is weaker than the public intent for the reported
bug. No obligation preserves the pre-fix zero behavior as intended.
