# Iteration Guidance

Status: constructed, not machine-checked.

## Code outcome

V1 fixed the reported signed-name regression. FVK found one refinement: V1's offset classifier was prefix-based rather than numeric-offset-based. V2 applies that refinement in `BaseDatabaseOperations._split_tzname_delta()` with an anchored numeric regex.

No additional production code changes are justified by the current public evidence.

## Suggested tests for a future normal test pass

Do not modify tests in this task. For a future test-authoring pass, add or confirm coverage for:

- PostgreSQL SQL generation with `Etc/GMT-10` and `Etc/GMT+10`.
- MySQL `CONVERT_TZ()` target argument with `Etc/GMT-10` and fixed offsets.
- Oracle timezone conversion target argument with signed IANA names.
- SQLite datetime parsing with `Etc/GMT-10`, `UTC+05:00`, `+0500`, and `+10`.
- Negative classifier examples such as `UTC+BAD` if private helper tests are acceptable.

## Residual risk

The proof is constructed but not machine-checked. Database engine behavior for named timezone tables is intentionally outside this fix; Django's obligation is to pass the correct timezone string to the backend.
