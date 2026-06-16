# Spec Audit

Status: constructed, not machine-checked.

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| C0 | Pass | E3 and E6 require `--check` to get the existing no-write dry-run behavior. |
| C1 | Pass | E1, E2, E4, and E5 require non-zero check failure without making migrations. |
| C2 | Pass for no-write and non-zero status under successful update preconditions | E2 says no migration-making file effects; `--update` is a migration-writing path, so it is included. The update-specific validation precondition is implementation-derived and named in A2. |
| C3 | Pass | E7 supports success when no changes exist; E2 still forbids writes. |
| C4 | Pass for no-write, implementation-derived for exact return status | E2 covers no writes. Public intent does not specify `--check --empty` status, so status is not used as a repair justification. |
| C5 | Pass for no-write, implementation-derived for exact return status | E2 covers no writes. Public intent does not specify `--check --merge` status, so status is not used as a repair justification. |
| C6 | Pass | I5 requires ordinary non-check behavior to remain unchanged; this frame condition is supported by the management command's existing purpose. |

## Adequacy conclusion

The formal claims cover the whole public-intent behavior space relevant to this
issue: normal missing migrations, no missing migrations, and migration-writing
variants reachable through `--update`, `--empty`, and merge handling. The only
implementation-derived parts are exact statuses for `--empty` and merge paths,
and those are explicitly excluded from the success argument.

