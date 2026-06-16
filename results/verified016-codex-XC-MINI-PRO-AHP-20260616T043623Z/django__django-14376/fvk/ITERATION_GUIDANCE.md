# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by the FVK audit.

The current source already satisfies the issue-derived obligation:

- Replace Django-generated `db` with `database`.
- Replace Django-generated `passwd` with `password`.

## If Continuing

1. Do not change test files in this benchmark.
2. If tests were allowed, add focused public tests for
   `DatabaseWrapper.get_connection_params()` confirming:
   - `NAME` appears as `database`.
   - `PASSWORD` appears as `password`.
   - `db` and `passwd` are absent when not supplied in `OPTIONS`.
   - canonical `OPTIONS['database']` and `OPTIONS['password']` override
     standard settings.
3. Keep arbitrary `OPTIONS` pass-through unless a future public requirement
   explicitly asks Django to normalize or reject deprecated user-supplied
   mysqlclient aliases.
4. To machine-check the constructed proof outside this environment, run the
   commands recorded in `fvk/PROOF.md`.

## Residual Risk

The proof is constructed, not machine-checked. It establishes partial
correctness of the dictionary-building path under the stated preconditions; it
does not execute mysqlclient and does not prove driver-level behavior.
