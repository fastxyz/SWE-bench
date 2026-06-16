# Spec Audit

Adequacy gate comparing `FORMAL_SPEC_ENGLISH.md` against `INTENT_SPEC.md`.

| Formal Claim | Intent Items | Result | Notes |
| --- | --- | --- | --- |
| `VISIT` uses sorted entries, emits all entries, then descends into `isDirFollow(E) and R(E)` entries. | I1, I2, I3 | PASS | Captures the issue's required follow behavior and preserves recursion filters. |
| `VISIT-SYMLINK-DIR` descends through symlink directory `E.path`. | I1, I2, I4 | PASS | The claim states the symlink path, not the real target path. |
| `VISIT-RECURSE-FILTER` blocks descent when `R(E)` is false. | I3 | PASS | Prevents the fix from bypassing `pytest_ignore_collect` or `norecursedirs`. |
| `VISIT-BROKEN-SYMLINK` does not recurse into broken symlinks. | I5 | PASS | Compatible with existing package-collection comments and public symlink tests. |
| Finite acyclic traversal side condition. | D1 | PASS WITH RESIDUAL RISK | Partial correctness is acceptable for this audit, but total correctness for symlink cycles is not proved. |
| Path spelling is preserved as `entry.path`. | I4, D2 | PASS | Avoids contradicting the public "symlinks are no longer resolved" behavior. |

No required behavior is marked FAIL or AMBIGUOUS.

